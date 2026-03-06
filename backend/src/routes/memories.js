import express from 'express'
import { supabaseAdmin } from '../config/supabaseClient.js'
import { requireFamilyRole } from '../middlewares/roleMiddleware.js'
import { enforceInheritanceRules } from '../middlewares/inheritanceMiddleware.js'

const router = express.Router()

// Create memory metadata (actual media is uploaded to Firebase Storage from the client)
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
        media_type: mediaType,
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

    res.status(201).json(memory)
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

    res.json(data)
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

    res.json(memory)
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

