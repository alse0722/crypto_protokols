require './methods'

class Shamir
  def initialize(params = {})
    @debug_mode = params.dig(:debug_mode).to_sym
    @bit_length = params.dig(:bit_length).to_i

    @methods = Methods.new(methods_params)
  end

  private

  def make_client(name, p)

    a = @methods.find_coprime(p - 1)
    a_inv = @methods.find_inv_coprime(a, p)

    {
      name: name,
      a: a,
      a_inv: a_inv
    }
  end
  
  def step0
    p = @methods.gen_large_p

    alice = make_client(p, 'Alice')
    bob = make_client(p, 'Bob')

    if @debug_mode == :all
      puts "[Init] Client A: #{alice}"
      puts "[Init] Client B: #{bob}"
    end
  end

  
end