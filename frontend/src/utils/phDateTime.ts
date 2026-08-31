// Asia/Manila has a fixed UTC+8 offset (no DST, ever), so converting between a naive
// datetime-local value and a real UTC instant is fixed ±8h arithmetic — not a general timezone
// problem, so no date library (none is installed) is needed. See
// kos/decisions/utc-storage-ph-display.md.
const PH_OFFSET_MS = 8 * 60 * 60_000

// UTC ISO instant (as returned by OperatorTripPresenter, already carrying a +08:00 offset) ->
// naive "YYYY-MM-DDTHH:mm" for pre-filling <input type="datetime-local">.
export function isoToPhDateTimeLocal(iso: string): string {
  const phMs = new Date(iso).getTime() + PH_OFFSET_MS
  return new Date(phMs).toISOString().slice(0, 16)
}

// naive "YYYY-MM-DDTHH:mm" from <input type="datetime-local"> (interpreted as PH wall-clock
// time) -> a real UTC ISO instant for the API payload.
export function phDateTimeLocalToIso(local: string): string {
  const naiveMs = new Date(`${local}:00Z`).getTime() // treat as if UTC first
  return new Date(naiveMs - PH_OFFSET_MS).toISOString()
}
