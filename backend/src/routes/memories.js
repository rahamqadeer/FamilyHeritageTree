import express from 'express'
import multer from 'multer'
import { supabaseAdmin } from '../config/supabaseClient.js'
import { requireFamilyRole } from '../middlewares/roleMiddleware.js'
import { enforceInheritanceRules } from '../middlewares/inheritanceMiddleware.js'

const router = express.Router()
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 }
})

function normalizeMediaType (mediaType) {
  const upper = String(mediaType || '').toUpperCase()
  if (upper === 'IMAGE' || upper === 'PHOTO') return 'photo'
  if (upper === 'VIDEO') return 'video'
  if (upper === 'AUDIO') return 'audio'
  if (upper === 'DOCUMENT' || upper === 'TEXT') return 'text'
  return 'photo'
}

const MEMORY_BUCKET = 'memories'
const SIGNED_URL_TTL_SEC = 60 * 60

/** Object path inside the `memories` bucket (not the public HTTP URL). */
function extractStorageObjectPath (storagePath) {
  if (!storagePath || typeof storagePath !== 'string') return null
  const trimmed = storagePath.trim()
  if (!trimmed.startsWith('http')) return trimmed

  const publicMatch = trimmed.match(/\/object\/public\/memories\/(.+?)(?:\?|$)/)
  if (publicMatch) return decodeURIComponent(publicMatch[1])

  const signedMatch = trimmed.match(/\/object\/sign\/memories\/(.+?)(?:\?|$)/)
  if (signedMatch) return decodeURIComponent(signedMatch[1])

  return trimmed
}

async function resolveMemoryMediaUrl (storagePath) {
  const objectPath = extractStorageObjectPath(storagePath)
  if (!objectPath) return null

  const { data, error } = await supabaseAdmin.storage
    .from(MEMORY_BUCKET)
    .createSignedUrl(objectPath, SIGNED_URL_TTL_SEC)

  if (!error && data?.signedUrl) {
    return data.signedUrl
  }

  console.error('Signed URL error', error)
  const { data: pub } = supabaseAdmin.storage
    .from(MEMORY_BUCKET)
    .getPublicUrl(objectPath)
  return pub.publicUrl
}

async function serializeMemory (row) {
  if (!row) return row
  const mediaUrl = row.storage_path
    ? await resolveMemoryMediaUrl(row.storage_path)
    : null
  return {
    ...row,
    created_at: row.created_at ?? new Date().toISOString(),
    media_url: mediaUrl
  }
}

// Upload media file to Supabase Storage (service role — works on web & mobile)
router.post(
  '/upload-media',
  upload.single('file'),
  requireFamilyRole(['ADMIN', 'ADULT']),
  async (req, res) => {
    try {
      const familyId = req.body.familyId || req.params.familyId
      const file = req.file

      if (!familyId) {
        return res.status(400).json({ message: 'familyId is required' })
      }
      if (!file) {
        return res.status(400).json({ message: 'file is required' })
      }

      const safeName = (file.originalname || 'upload.bin').replace(/[^a-zA-Z0-9._-]/g, '_')
      const storagePath = `memories/${familyId}/${Date.now()}_${safeName}`

      const { error: uploadError } = await supabaseAdmin.storage
        .from('memories')
        .upload(storagePath, file.buffer, {
          contentType: file.mimetype || 'application/octet-stream',
          upsert: false
        })

      if (uploadError) {
        console.error('Storage upload error', uploadError)
        return res.status(500).json({
          message: uploadError.message || 'Failed to upload file to storage'
        })
      }

      const { data: publicData } = supabaseAdmin.storage
        .from('memories')
        .getPublicUrl(storagePath)

      res.status(201).json({
        storagePath,
        publicUrl: publicData.publicUrl
      })
    } catch (err) {
      console.error('Upload media error', err)
      res.status(500).json({ message: 'Failed to upload media' })
    }
  }
)

// Create memory metadata after media is uploaded
router.post('/', requireFamilyRole(['ADMIN', 'ADULT']), async (req, res) => {
  try {
    const {
      familyId,
      title,
      description,
      mediaType,
      storagePath,
      event,
      eventDate,
      tags,
      peopleNodeIds
    } = req.body

    if (!familyId || !title || !mediaType) {
      return res.status(400).json({ message: 'familyId, title and mediaType are required' })
    }

    const { data: memory, error } = await supabaseAdmin
      .from('memories')
      .insert({
        family_id: familyId,
        created_by: req.auth.user.id,
        title,
        description,
        media_type: normalizeMediaType(mediaType),
        storage_path: storagePath,
        event,
        event_date: eventDate,
        tags
      })
      .select('*')
      .single()

    if (error) {
      console.error('Create memory error', error)
      return res.status(500).json({ message: 'Failed to create memory' })
    }

    if (Array.isArray(peopleNodeIds) && peopleNodeIds.length > 0) {
      const rows = peopleNodeIds.map(nodeId => ({
        memory_id: memory.id,
        node_id: nodeId
      }))

      const { error: tagError } = await supabaseAdmin
        .from('memory_people_tags')
        .insert(rows)

      if (tagError) {
        console.error('Memory people tag error', tagError)
      }
    }

    res.status(201).json(await serializeMemory(memory))
  } catch (err) {
    console.error('Create memory error', err)
    res.status(500).json({ message: 'Failed to create memory' })
  }
})

// List memories for a family (respecting role & inheritance engine)
router.get('/', requireFamilyRole(['ADMIN', 'ADULT', 'JUNIOR']), async (req, res) => {
  try {
    const { familyId } = req.query
    if (!familyId) {
      return res.status(400).json({ message: 'familyId is required' })
    }

    const { data, error } = await supabaseAdmin
      .from('memories')
      .select('*')
      .eq('family_id', familyId)
      .order('created_at', { ascending: false })

    if (error) {
      console.error('List memories error', error)
      return res.status(500).json({ message: 'Failed to list memories' })
    }

    const memories = await Promise.all((data ?? []).map(serializeMemory))
    res.json(memories)
  } catch (err) {
    console.error('List memories error', err)
    res.status(500).json({ message: 'Failed to list memories' })
  }
})

// Get a single memory with inheritance check
router.get('/:memoryId', requireFamilyRole(['ADMIN', 'ADULT', 'JUNIOR']), enforceInheritanceRules(), async (req, res) => {
  try {
    const { memoryId } = req.params

    const { data: memory, error } = await supabaseAdmin
      .from('memories')
      .select('*')
      .eq('id', memoryId)
      .single()

    if (error || !memory) {
      return res.status(404).json({ message: 'Memory not found' })
    }

    res.json(await serializeMemory(memory))
  } catch (err) {
    console.error('Get memory error', err)
    res.status(500).json({ message: 'Failed to load memory' })
  }
})

// Set inheritance rule for a memory (admin only)
router.post('/:memoryId/inheritance-rules', requireFamilyRole(['ADMIN']), async (req, res) => {
  try {
    const { memoryId } = req.params
    const { familyId, beneficiaryNodeId, conditionType, unlockDate, unlockAge } = req.body

    if (!familyId || !beneficiaryNodeId || !conditionType) {
      return res.status(400).json({ message: 'familyId, beneficiaryNodeId and conditionType are required' })
    }

    if (!['UNLOCK_AT_DATE', 'UNLOCK_AT_AGE'].includes(conditionType)) {
      return res.status(400).json({ message: 'Invalid conditionType' })
    }

    if (conditionType === 'UNLOCK_AT_DATE' && !unlockDate) {
      return res.status(400).json({ message: 'unlockDate required for UNLOCK_AT_DATE' })
    }

    if (conditionType === 'UNLOCK_AT_AGE' && !unlockAge) {
      return res.status(400).json({ message: 'unlockAge required for UNLOCK_AT_AGE' })
    }

    const { data: rule, error } = await supabaseAdmin
      .from('inheritance_rules')
      .insert({
        memory_id: memoryId,
        family_id: familyId,
        beneficiary_node_id: beneficiaryNodeId,
        condition_type: conditionType,
        unlock_date: unlockDate,
        unlock_age: unlockAge,
        created_by: req.auth.user.id
      })
      .select('*')
      .single()

    if (error) {
      console.error('Create inheritance rule error', error)
      return res.status(500).json({ message: 'Failed to create inheritance rule' })
    }

    res.status(201).json(rule)
  } catch (err) {
    console.error('Create inheritance rule error', err)
    res.status(500).json({ message: 'Failed to create inheritance rule' })
  }
})

export default router

