class Coder
  def initialize(params = {})
    @p = params.dig(:p).to_i
    @bit_length = params.dig(:bit_length).to_i

    @a, @b = generate_ab(@p)
  end

  def encode(message, type = :raw)
    case type
    when :raw
      encoded_message = message.bytes.map { |c| c.pow(@a, @p) }
      encoded_message.join(",")
    when :enc
      encoded_message = message.split(',').map { |c| c.to_i.pow(@a, @p) }
      encoded_message.join(",")
    end
  end

  def decode(encoded_message, type = :raw)
    case type
    when :raw
      encoded_message.split(",").map { |c| c.to_i.pow(@b, @p) }.pack("C*")
    when :enc
      decoded_message = encoded_message.split(",").map { |c| c.to_i.pow(@b, @p) }
      decoded_message.join(",")
    end
  end

  def get_params
    { 
      p: @p,
      a: @a,
      b: @b
    }
  end

  private

  def generate_ab(p)
    a = find_coprime(p - 1)
    b = modular_inverse(a, p - 1)
    [a, b]
  end

  def find_coprime(n)
    random = Random.new
    candidate = random.rand(2..n-1)

    until candidate.gcd(n) == 1
      candidate = (candidate + 1) % n
    end

    candidate
  end

  def modular_inverse(a, p)
    x, y = extended_gcd(a, p)
    x += p if x < 0
    x
  end

  def extended_gcd(a, b)
    return [0, 1] if a % b == 0
    x, y = extended_gcd(b, a % b)
    [y, x - (a / b) * y]
  end

end
