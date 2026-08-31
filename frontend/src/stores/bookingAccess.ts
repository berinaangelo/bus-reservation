import { ref } from 'vue'
import { defineStore } from 'pinia'
import { normalizeReferenceCode } from '../utils/referenceCode'

// Carries the verified reference_code + contact_number pair across navigation into
// BookingDetailView — that pair is the entire v1 "account system" (god moment #5,
// kos/decisions/mvp-scope.md), and GET/PATCH /bookings/:reference_code both require
// contact_number on every call since there's no rider session/token. Set by whichever screen
// just proved the pair (BookingLookupView after a successful find, ETicketConfirmationView on
// mount) right before it links into Booking Detail.
//
// Deliberately holds only the credential pair, not a cached Booking — BookingDetailView always
// re-fetches fresh via GET, since its whole purpose is showing *current* status, not what was
// true at the moment of the last lookup. Same in-memory-only, not-persisted shape as
// checkout.ts's lastBooking: a page refresh loses it by design, and BookingDetailView falls back
// to Booking Lookup in that case.
export const useBookingAccessStore = defineStore('bookingAccess', () => {
  const referenceCode = ref('')
  const contactNumber = ref('')

  // Normalizes so every caller (BookingLookupView already passes a normalized code,
  // ETicketConfirmationView passes the dashed display format off Booking) lands in the same
  // shape here — callers never need to think about which form they're holding.
  function setVerified(refCode: string, contact: string) {
    referenceCode.value = normalizeReferenceCode(refCode)
    contactNumber.value = contact
  }

  return { referenceCode, contactNumber, setVerified }
})
