import express from 'express'
import { supabaseAdmin } from '../config/supabaseClient.js'
import { requireFamilyRole } from '../middlewares/roleMiddleware.js'

const router = express.Router()

// Create a new family vault; creator becomes ADMIN
router.post('/', async (req, res) => {
  try {
    const { name } = req.body
    if (!name) {
      return res.status(400).json({ message: 'Family name is required' })
    }

    const userId = req.auth.user.id

    const { data: family, error: famError } = await supabaseAdmin
      .from('families')
      .insert({
        name,
        created_by: userId
      })
      .select('*')
      .single()

    if (famError) {
      console.error('Error creating family', famError)
      return res.status(500).json({ message: 'Failed to create family' })
    }

    const { error: memberError } = await supabaseAdmin
      .from('family_members')
      .insert({
        family_id: family.id,
        user_id: userId,
        role: 'ADMIN'
      })

    if (memberError) {
      console.error('Error creating admin membership', memberError)
      return res.status(500).json({ message: 'Failed to assign admin role' })
    }

    res.status(201).json(family)
  } catch (err) {
    console.error('Create family error', err)
    res.status(500).json({ message: 'Failed to create family' })
  }
})

// List families for current user
router.get('/', async (req, res) => {
  try {
    const userId = req.auth.user.id

    const { data, error } = await supabaseAdmin
      .from('family_members')
      .select('family_id, role, families (id, name, created_at)')
      .eq('user_id', userId)

    if (error) {
      console.error('List families error', error)
      return res.status(500).json({ message: 'Failed to list families' })
    }

    const families = (data || []).map(row => ({
      id: row.families.id,
      name: row.families.name,
      created_at: row.families.created_at,
      role: row.role
    }))

    res.json(families)
  } catch (err) {
    console.error('List families error', err)
    res.status(500).json({ message: 'Failed to list families' })
  }
})

// Invite member via email (stores pending membership; email sending handled separately)
router.post('/:familyId/invite', requireFamilyRole(['ADMIN']), async (req, res) => {
  try {
    const { email, role } = req.body
    const { familyId } = req.params

    if (!email) {
      return res.status(400).json({ message: 'Email is required' })
    }

    const normalizedRole = role || 'ADULT'
    if (!['ADMIN', 'ADULT', 'JUNIOR'].includes(normalizedRole)) {
      return res.status(400).json({ message: 'Invalid role' })
    }

    const { data, error } = await supabaseAdmin
      .from('family_members')
      .insert({
        family_id: familyId,
        user_id: req.auth.user.id, // placeholder until invite is accepted and linked to a user
        role: normalizedRole,
        invited_email: email
      })
      .select('*')
      .single()

    if (error) {
      console.error('Invite member error', error)
      return res.status(500).json({ message: 'Failed to create invitation' })
    }

    // In production, trigger email sending here or via a separate service.
    res.status(201).json({
      invitationId: data.id,
      message: 'Invitation recorded; send an email with app instructions containing this family ID.'
    })
  } catch (err) {
    console.error('Invite member error', err)
    res.status(500).json({ message: 'Failed to invite member' })
  }
})

export default router
