import { request } from '../client'
import type { PaginationMeta } from '../types'
import type { ManifestRow, ManifestSummary } from '../../types/operator'

interface ManifestResponse {
  summary: ManifestSummary
  rows: ManifestRow[]
  meta: PaginationMeta
}

// GET /api/v1/operator/trips/:trip_id/manifest
export function getManifest(tripId: number, page?: number) {
  return request<ManifestResponse>(`/operator/trips/${tripId}/manifest`, {
    params: { page },
    auth: true,
  })
}
