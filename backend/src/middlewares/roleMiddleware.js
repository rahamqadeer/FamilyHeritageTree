// Role-based access control middleware
// Expects req.auth.user.id and a family_id param or body field.

import { supabaseAdmin } from '../config/supabaseClient.js'

export function requireFamilyRole (allowedRoles = []) {
  return async function (req, res, next) {
    try {
      const userId = req.auth?.user?.id
      const familyId = req.params.familyId || req.body.familyId || req.query.familyId

      if (!userId || !familyId) {
        return res.status(400).json({ message: 'Missing user or family context' })
      }

      const { data: membership, error } = await supabaseAdmin
        .from('family_members')
        .select('role')
        .eq('family_id', familyId)
        .eq('user_id', userId)
        .single()

      if (error) {
        console.error('Role middleware membership error', error)
        return res.status(403).json({ message: 'Not a member of this family' })
      }

      if (allowedRoles.length > 0 && !allowedRoles.includes(membership.role)) {
        return res.status(403).json({ message: 'Insufficient role for this operation' })
      }

      req.auth.familyRole = membership.role
      next()
    } catch (err) {
      console.error('Role middleware error', err)
      return res.status(500).json({ message: 'Role validation failed' })
    }
  }
}
