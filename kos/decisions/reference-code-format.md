---
title: reference-code-format
tags: [bus-reservation, data-model, booking]
date: 2026-08-25
---

Booking.reference_code format: 6 random alphanumeric characters, uppercase, drawn from an
unambiguous charset (excludes `0/O`, `1/I/L`), displayed grouped 3+3 with a dash, plus a 1-char
checksum suffix — e.g. `4XK-7QM-9`.

Why: QR camera-scan check-in is cut from MVP (see [[mvp-scope]]), so terminal staff hand-type
this code at the boarding counter to pull up a booking. An earlier `S_<TIMESTAMP>_ID` format was
rejected as too long to type accurately and unnecessarily predictable. The checksum char is
computed from the other 6 so a single mistyped character is caught immediately (lookup fails
loudly) instead of silently returning nothing or, worse, someone else's booking. Same pattern as
airline PNRs — familiar, short, sayable aloud.

**Checksum algorithm (finalized): Luhn mod N**, generalizing the credit-card Luhn algorithm to
this project's 31-character alphabet (`23456789ABCDEFGHJKMNPQRSTUVWXYZ` — digits 0/1 and letters
I/L/O excluded per the unambiguous-charset rule above). Catches a single mistyped character and
an adjacent-character swap — the two typo types that actually happen at a counter — without
needing a second, extended alphabet just for the check symbol (unlike Crockford Base32's own
checksum scheme).

```ruby
module ReferenceCode
  ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ".freeze # N = 31, no 0/1/I/L/O

  def self.checksum(code)
    n = ALPHABET.length
    factor = 2
    sum = 0

    code.reverse.each_char do |char|
      addend = factor * ALPHABET.index(char)
      factor = factor == 2 ? 1 : 2
      addend = (addend / n) + (addend % n)
      sum += addend
    end

    remainder = sum % n
    ALPHABET[(n - remainder) % n]
  end

  def self.valid?(full_code) # full_code includes the trailing checksum char
    body, check = full_code[0..-2], full_code[-1]
    checksum(body) == check
  end
end
```

No gem dependency — this is small enough to hand-roll and keep in one file
(`app/lib/reference_code.rb` or similar) rather than pull in a Luhn gem that likely assumes the
standard base-10 alphabet.

**How to apply:** generate the 6-char body from `ALPHABET`, append `checksum(body)` as the 7th
character, format for display as `XXX-XXX-C`. On lookup, strip the dashes and run `valid?` before
hitting the DB — an invalid checksum means a typo, not a missing booking, so surface that
distinction to the counter staff instead of a generic "not found."
