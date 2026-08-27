# Generates and validates the rider-facing booking lookup code. See
# kos/decisions/reference-code-format.md: 6 random chars from an unambiguous 31-char alphabet
# (no 0/O, 1/I/L) plus a 1-char Luhn-mod-N checksum, so staff hand-typing this at the boarding
# counter catch a single mistyped character immediately.
#
# `Booking#reference_code` stores the raw 7-char code (no dashes); `.format` renders the
# display grouping (XXX-XXX-C) and lookups strip the dashes again before calling `.valid?`.
module ReferenceCode
  ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ".freeze # N = 31, no 0/1/I/L/O

  BODY_LENGTH = 6

  def self.generate
    body = Array.new(BODY_LENGTH) { ALPHABET[SecureRandom.random_number(ALPHABET.length)] }.join
    body + checksum(body)
  end

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

  def self.valid?(full_code)
    return false if full_code.blank? || full_code.length != BODY_LENGTH + 1

    body, check = full_code[0..-2], full_code[-1]
    return false unless (body + check).chars.all? { |c| ALPHABET.include?(c) }

    checksum(body) == check
  end

  def self.format(full_code)
    body = full_code[0..-2]
    "#{body[0..2]}-#{body[3..5]}-#{full_code[-1]}"
  end
end
