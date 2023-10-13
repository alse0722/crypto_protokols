require 'prime'

class Methods
  def initialize(params = {})
    @debug_mode = params.dig(:debug_mode).to_sym
    @bit_length = params.dig(:bit_length).to_i
  end

  def gen_large_p
    loop do
      candidate = rand(2 ** @bit_length)
      # pp candidate
      next if candidate.even?
    
      if Prime.prime?(candidate)
        factors = Prime.prime_division(candidate - 1)
        largest_prime_factor = factors[-1][0]
        return candidate if largest_prime_factor > Math.sqrt(candidate).to_i
      end
    end
  end

  def exea(a, b)
    return [0, 1] if a % b == 0
    x, y = exea(b, a % b)
    [y, x - (a / b) * y]
  end
  
  def inv(a, p)
    x, y = exea(a, p)
    x += p if x < 0
    x
  end

  def find_coprime(n)
    loop do
      a = rand(2..n-1)
      return a if a.prime? && (a - 1).prime?
    end
  end

  def find_inv_coprime(a, p)
    a_inv = 1

    while (a * a_inv) % (p - 1) != 1
      a_inv += 1
    end

    a_inv
  end

end