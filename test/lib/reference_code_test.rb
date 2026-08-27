require "test_helper"

class ReferenceCodeTest < ActiveSupport::TestCase
  test "generates a 7-char uppercase code from the alphabet" do
    code = ReferenceCode.generate

    assert_equal 7, code.length
    assert code.chars.all? { |c| ReferenceCode::ALPHABET.include?(c) }
  end

  test "a generated code passes its own validity check" do
    50.times do
      assert ReferenceCode.valid?(ReferenceCode.generate)
    end
  end

  test "rejects a single mutated character" do
    5.times do
      code = ReferenceCode.generate
      mutated = mutate_char(code, 0)

      assert_not ReferenceCode.valid?(mutated)
    end
  end

  test "rejects an adjacent-character swap" do
    5.times do
      code = swappable_code
      swapped = swap_adjacent(code, 0)

      assert_not ReferenceCode.valid?(swapped)
    end
  end

  test "rejects blank or wrong-length input" do
    assert_not ReferenceCode.valid?(nil)
    assert_not ReferenceCode.valid?("")
    assert_not ReferenceCode.valid?(ReferenceCode.generate[0..-2])
    assert_not ReferenceCode.valid?("#{ReferenceCode.generate}X")
  end

  test "format groups as XXX-XXX-C and round-trips through dash-stripping" do
    code = ReferenceCode.generate

    formatted = ReferenceCode.format(code)

    assert_match(/\A[#{ReferenceCode::ALPHABET}]{3}-[#{ReferenceCode::ALPHABET}]{3}-[#{ReferenceCode::ALPHABET}]\z/, formatted)
    assert_equal code, formatted.delete("-")
  end

  private

  def mutate_char(code, index)
    alphabet = ReferenceCode::ALPHABET
    current = code[index]
    replacement = (alphabet.chars - [ current ]).sample
    code.dup.tap { |c| c[index] = replacement }
  end

  # A code whose first two characters differ, so swapping them is an actual mutation.
  def swappable_code
    code = ReferenceCode.generate
    code = ReferenceCode.generate while code[0] == code[1]
    code
  end

  def swap_adjacent(code, index)
    chars = code.chars
    chars[index], chars[index + 1] = chars[index + 1], chars[index]
    chars.join
  end
end
