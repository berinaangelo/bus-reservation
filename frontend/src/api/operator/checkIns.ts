import { request } from '../client'
import type { ManifestRow } from '../../types/operator'

// POST /api/v1/operator/trips/:trip_id/check_ins — takes only reference_code (scoped to the
// trip, no contact_number), returns the updated manifest rows (not a booking).
export function checkIn(tripId: number, referenceCode: string) {
  return request<{ rows: ManifestRow[] }>(`/operator/trips/${tripId}/check_ins`, {
    method: 'POST',
    body: { reference_code: referenceCode },
    auth: true,
  })
}
