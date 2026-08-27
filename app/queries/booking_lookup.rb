# Guest booking lookup by reference_code + contact_number -- this IS the account system for v1,
# see kos/decisions/mvp-scope.md. Not a plain `.where`: per kos/decisions/reference-code-format.md,
# an invalid checksum means a typo, not a missing booking, so that distinction has to surface to
# the caller separately from "no such booking."
class BookingLookup
  def initialize(reference_code:, contact_number:)
    @reference_code = reference_code.to_s.delete("-").upcase
    @contact_number = contact_number.to_s.gsub(/\D/, "")
  end

  def invalid_code?
    !ReferenceCode.valid?(@reference_code)
  end

  def call
    Booking
      .includes(
        { trip: { route: [ :operator, :origin_terminal, :destination_terminal ] } },
        { passengers: { trip_seat: :seat } },
        :payment
      )
      .find_by(reference_code: @reference_code, contact_number: @contact_number)
  end
end
