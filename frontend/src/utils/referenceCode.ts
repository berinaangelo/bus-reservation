// Client-side mirror of app/lib/reference_code.rb's Luhn-mod-N checksum — lets Booking Lookup
// catch a mistyped character before it ever reaches the server (see
// kos/decisions/reference-code-format.md and kos/decisions/ux/mockups/booking-lookup.html's
// "Local — checksum fails" state). Keep this in lockstep with the Ruby module if either changes.

const ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ' // N = 31, no 0/1/I/L/O
const BODY_LENGTH = 6

// Strips dashes/spaces and uppercases — mirrors BookingLookup's own normalization server-side, so
// "4xk-7qm-9" and "4XK7QM9" both validate/submit the same as "4XK-7QM-9".
export function normalizeReferenceCode(input: string): string {
  return input.replace(/[-\s]/g, '').toUpperCase()
}

function checksum(body: string): string {
  const n = ALPHABET.length
  let factor = 2
  let sum = 0
  for (const char of [...body].reverse()) {
    let addend = factor * ALPHABET.indexOf(char)
    factor = factor === 2 ? 1 : 2
    addend = Math.floor(addend / n) + (addend % n)
    sum += addend
  }
  const remainder = sum % n
  return ALPHABET[(n - remainder) % n]
}

// Expects an already-normalized code (see normalizeReferenceCode). False for anything the wrong
// length or containing a character outside the alphabet, not just a checksum mismatch.
export function isValidReferenceCode(code: string): boolean {
  if (code.length !== BODY_LENGTH + 1) return false

  const body = code.slice(0, -1)
  const check = code.slice(-1)
  if (![...body, check].every((c) => ALPHABET.includes(c))) return false

  return checksum(body) === check
}
