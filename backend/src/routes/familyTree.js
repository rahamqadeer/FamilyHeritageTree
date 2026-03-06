import express from 'express'
import { supabaseAdmin } from '../config/supabaseClient.js'
import { requireFamilyRole } from '../middlewares/roleMiddleware.js'

const router = express.Router()

// Create or update a family tree node
router.post('/:familyId/nodes', requireFamilyRole(['ADMIN', 'ADULT']), async (req, res) => {
  try {
    const { familyId } = req.params
    const { id, fullName, birthDate, deathDate, metadata, userId } = req.body

    if (!fullName) {
      return res.status(400).json({ message: 'fullName is required' })
    }

    if (id) {
      const { data, error } = await supabaseAdmin
        .from('family_tree_nodes')
        .update({
          full_name: fullName,
          birth_date: birthDate,
          death_date: deathDate,
          metadata,
          user_id: userId
        })
        .eq('id', id)
        .eq('family_id', familyId)
        .select('*')
        .single()

      if (error) {
        console.error('Update node error', error)
        return res.status(500).json({ message: 'Failed to update node' })
      }

      return res.json(data)
    } else {
      const { data, error } = await supabaseAdmin
        .from('family_tree_nodes')
        .insert({
          family_id: familyId,
          full_name: fullName,
          birth_date: birthDate,
          death_date: deathDate,
          metadata,
          user_id: userId
        })
        .select('*')
        .single()

      if (error) {
        console.error('Create node error', error)
        return res.status(500).json({ message: 'Failed to create node' })
      }

      return res.status(201).json(data)
    }
  } catch (err) {
    console.error('Node upsert error', err)
    res.status(500).json({ message: 'Failed to save node' })
  }
})

// Define relationships between nodes
router.post('/:familyId/relationships', requireFamilyRole(['ADMIN', 'ADULT']), async (req, res) => {
  try {
    const { familyId } = req.params
    const { fromNodeId, toNodeId, type } = req.body

    if (!fromNodeId || !toNodeId || !type) {
      return res.status(400).json({ message: 'fromNodeId, toNodeId and type are required' })
    }

    if (!['PARENT', 'CHILD', 'SPOUSE'].includes(type)) {
      return res.status(400).json({ message: 'Invalid relationship type' })
    }

    const { data, error } = await supabaseAdmin
      .from('family_relationships')
      .insert({
        family_id: familyId,
        from_node_id: fromNodeId,
        to_node_id: toNodeId,
        type
      })
      .select('*')
      .single()

    if (error) {
      console.error('Create relationship error', error)
      return res.status(500).json({ message: 'Failed to create relationship' })
    }

    res.status(201).json(data)
  } catch (err) {
    console.error('Create relationship error', err)
    res.status(500).json({ message: 'Failed to create relationship' })
  }
})

// Get tree (nodes + relationships) for a family
router.get('/:familyId', requireFamilyRole(['ADMIN', 'ADULT', 'JUNIOR']), async (req, res) => {
  try {
    const { familyId } = req.params

    const [{ data: nodes, error: nodesError }, { data: relationships, error: relError }] =
      await Promise.all([
        supabaseAdmin
          .from('family_tree_nodes')
          .select('*')
          .eq('family_id', familyId),
        supabaseAdmin
          .from('family_relationships')
          .select('*')
          .eq('family_id', familyId)
      ])

    if (nodesError || relError) {
      console.error('Load tree error', nodesError || relError)
      return res.status(500).json({ message: 'Failed to load family tree' })
    }

    res.json({ nodes, relationships })
  } catch (err) {
    console.error('Get tree error', err)
    res.status(500).json({ message: 'Failed to load family tree' })
  }
})

// Safe delete node: prevent deletion if it would break tree integrity (e.g., node with children)
router.delete('/:familyId/nodes/:nodeId', requireFamilyRole(['ADMIN']), async (req, res) => {
  try {
    const { familyId, nodeId } = req.params

    const { data: relationships, error } = await supabaseAdmin
      .from('family_relationships')
      .select('id')
      .or(`from_node_id.eq.${nodeId},to_node_id.eq.${nodeId}`)
      .eq('family_id', familyId)

    if (error) {
      console.error('Check node relationships error', error)
      return res.status(500).json({ message: 'Failed to validate node deletion' })
    }

    if (relationships && relationships.length > 0) {
      return res.status(400).json({
        message: 'Cannot delete a node that is part of existing relationships. Remove relationships first.'
      })
    }

    const { error: deleteError } = await supabaseAdmin
      .from('family_tree_nodes')
      .delete()
      .eq('id', nodeId)
      .eq('family_id', familyId)

    if (deleteError) {
      console.error('Delete node error', deleteError)
      return res.status(500).json({ message: 'Failed to delete node' })
    }

    res.status(204).send()
  } catch (err) {
    console.error('Delete node error', err)
    res.status(500).json({ message: 'Failed to delete node' })
  }
})

export default router

