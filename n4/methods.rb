require 'securerandom'
require 'prime'

class Methods

  def initialize(params = {})
    @p_bit_length = params.dig(:p_bit_length) || 1024
    @q_bit_length = params.dig(:q_bit_length) || 160
    @t =            params.dig(:t) || 72

    @debug_mode = params.dig(:debug_mode) == :all
  end

  def make_keys(name = 'Client')
    puts "\n#{name} is generating start params"
    p = gen_large_p
    puts "Generated p: #{p}" if @debug_mode
    q = gen_del_q(p)
    puts "Generated q: #{q}" if @debug_mode
    g = gen_step_g(p, q)
    puts "Generated g: #{g}" if @debug_mode
    w = gen_rand_w(q)
    puts "Generated w: #{w}" if @debug_mode
    y = find_y(g, q, w, p)
    puts "Generated y: #{y}" if @debug_mode

    keys = {
      open_key:{
        p: p,
        q: q,
        g: g,
        y: y
      },
      secret_key:{
        w: w
      },
      process:{
      }
    }

    keys[:prep] = prep_enum(keys)
    puts "Generated r: #{keys[:prep][:r]}" if @debug_mode
    puts "Generated x: #{keys[:prep][:x]}" if @debug_mode

    return keys
  end

  private

  def gen_large_p
    loop do
      p = rand(2 ** @p_bit_length)
      return p if p.prime?
    end
  end

  def gen_del_q(p)
    loop do
      q = rand(2..Math.sqrt(p-1).to_i)
      return q if q.prime? && (p-1) % q == 0
    end
  end

  def gen_step_g(p, q)
    loop do
      g = rand(p)
      return g if g != 1 && g.pow(q, p) == 1 && g != 0
    end
  end

  def gen_rand_w(q)
    return rand(q)
  end

  def find_y(g, q, w, p)
    return g.pow(q - w, p)
  end

  def gen_rand_r(q)
    return rand(2..q)
  end

  def find_x(g, r, p)
    return g.pow(r, p)
  end

  def prep_enum(keys)
    r = gen_rand_r(keys[:open_key][:q])
    x = find_x(keys[:open_key][:g], r, keys[:open_key][:p])

    {
      r: r,
      x: x
    }
  end
end
# блэкли
# мийота