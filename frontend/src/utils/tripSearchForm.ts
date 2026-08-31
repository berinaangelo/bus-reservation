// Shared between TripSearchView (the standalone search form) and TripSearchResultsView (which
// embeds the same Route Line search bar so a rider can adjust and re-run a search without
// leaving the results screen).
import { searchTerminals } from '../api/terminals'
import type { SelectOption } from '../types/ui'

// Local (not UTC) so a rider near midnight in Asia/Manila doesn't get bumped to the wrong day —
// see kos/decisions/utc-storage-ph-display.md.
export function todayLocalISODate(): string {
  const now = new Date()
  const offsetMs = now.getTimezoneOffset() * 60_000
  return new Date(now.getTime() - offsetMs).toISOString().slice(0, 10)
}

export async function loadTerminals(q: string): Promise<SelectOption<number>[]> {
  const terminals = await searchTerminals(q)
  return terminals.map((t) => ({ label: `${t.name}, ${t.city}`, value: t.id }))
}
