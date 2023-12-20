require 'prime'
require 'openssl'
class Steps
  def initialize(params = {})
    @bit_length = params.dig(:bit_length)
    @debug_mode = params.dig(:debug_mode)
  end

  def step0
    puts "Генерация начальных параметров:"

    puts "Введите сообщение m:"
    @m = gets.strip.to_s

    @hm = one_way_hash(@m, 8).to_i(16)
    puts "Хэш сообщения hm: #{@hm}"

    q = get_more_prime(@hm)
    # q = next_prime_after(@hm)
    puts "Число q: #{q}"

    p = gen_p(q)
    puts "Число p: #{p}"

    g = 2.pow((p-1)/q) % p
    puts "Число g: #{g}"

    x = rand(q)
    puts "Число x: #{x}"

    y = g.pow(x, p)
    puts "Число y: #{y}"

    @main = {
      p: p,
      q: q,
      g: g
    }

    @secret_key = {
      x: x
    }

    @open_key = {
      y: y
    }

    puts "Итого параметры системы примут вид:"
    puts "Общие параметры: #{@main}"
    puts "Открытый ключ: #{@open_key}"
    puts "Закрытый ключ: #{@secret_key}"

    @alice = {name: "alice", get: [], send:[], processed: {}}
    @bob = {name: "bob", get: [], send:[], processed: {}}

    puts "\nКлиент #{@alice[:name]}: #{@alice}" if @debug_mode
    puts "Клиент #{@bob[:name]}: #{@bob}\n" if @debug_mode

  end

  def step1
    puts "Генерация подписи"
    puts "Какой бит передать? 1/0"
    bit = gets.strip.to_i

    s = 0
    r = 0

    while s == 0 || r == 0
      k = rand(@main[:q])
      r = (@main[:g].pow(k, @main[:p])).pow(1, @main[:q])

      case bit
      when 1
        while lezhandr2(r, @main[:p]) != 1
          k = rand(@main[:q])
          r = (@main[:g].pow(k, @main[:p])).pow(1, @main[:q])
        end
      when 0
        while lezhandr2(r, @main[:p]) != -1
          k = rand(@main[:q])
          r = (@main[:g].pow(k, @main[:p])).pow(1, @main[:q])
        end
      end

      s = (inverse(k, @main[:q]) * (@hm + @secret_key[:x] * r)) % @main[:q]
    end

    puts "В качестве секретного сообщения выбран бит #{bit}"
    puts "Вычислена величина k:#{k}"
    puts "Вычислена величина r:#{r}"
    puts "Вычислена величина s:#{s}"

    puts "\nA→B: {m, r, s}"
    @alice[:send] << {m: @m, r: r, s:s}
    @bob[:get] << @alice[:send].last
    @bob[:processed].merge!(@bob[:get].last)
    @alice[:processed].merge!(@alice[:send].last)
    @alice[:processed].merge!({m: @m, r: r, s:s})

    puts "Клиент #{@alice[:name]}: #{@alice}" if @debug_mode
    puts "Клиент #{@bob[:name]}: #{@bob}\n" if @debug_mode
  end

  def step2
    puts "\nПроверка подписи"
    data = @bob[:processed]
    u = inverse(data[:s], @main[:q])
    a = (@hm * u) % @main[:q]
    b = (data[:r] * u) % @main[:q]
    v = (@main[:g].pow(a, @main[:p]) * @open_key[:y].pow(b, @main[:p]) % @main[:p]) % @main[:q]

    puts "Вычислена величина u:#{u}"
    puts "Вычислена величина a:#{a}"
    puts "Вычислена величина b:#{b}"
    puts "Вычислена величина v:#{v}"
    puts "Результат проверки: #{v == data[:r] ? "ПРОЙДЕНА" : "НЕ ПРОЙДЕНА"}"

    puts "\nИзвлечение секретного сообщения:"
    puts "Проверка r дала бит: #{lezhandr2(data[:r], @main[:p]) == 1 ? "1" : "0"}"
  end

  private

  def gen_random_prime

    raise 'Not enough number length!' if @bit_length == 0
    
    num = 1
    while !num.prime?
      bin_str = '1'

      (@bit_length - 1).times do 
        bin_str += rand(2).to_s
      end

      num = bin_str.to_i(2)
    end
    num
  end

  def get_more_prime(n)
    if n % 2 == 0
      num = n + 1
    else
      num = n + 2
    end
    while !num.prime?
      num +=2
    end
    num
  end

  def one_way_hash(data, hash_length = 64)
    raise ArgumentError, 'Некорректная длина хэша' unless hash_length.positive?
  
    sha256 = OpenSSL::Digest::SHA256.new
    hashed_data = sha256.digest(data)
  
    # Получаем хэш длиной hash_length и возвращаем его
    hashed_data.unpack('H*')[0][0, hash_length]
  end

  def gen_p(q)
    # Проверяем, что q является простым числом
    raise ArgumentError, 'Входное число q не является простым' unless q.prime?
  
    # Генерируем простые числа, начиная с q+1, и проверяем, чтобы p-1 было делителем q
    # p_candidate = q + 1
  
    # loop do
    #   if p_candidate.prime? && (p_candidate - 1) % q == 0
    #     return p_candidate
    #   else
    #     p_candidate += 1
    #   end
    # end

    two = 2
    while !(two * q + 1).prime?
      two *= 2
    end

    two * q + 1
  end

  def lezhandr2(a, p)
    return 0 if a % p == 0

    a.pow((p-1)/2, p) == 1 ? 1 : -1
  end

  def gcd_ext(a, b, first = true)

    if a == 0
      return b, 0, 1
    else
      res, x, y = gcd_ext(b%a, a, false)
      return res, y - (b / a) * x, x
    end
  end

  def inverse(a, md)
    gcd, x, _ = gcd_ext(a, md)
    if gcd != 1
      raise "\nNo inverse element exists\n"
    else
      return x % md
    end
  end

  def next_prime_after(n)
    raise ArgumentError, 'Введите положительное число' unless n.is_a?(Integer) && n.positive?
  
    primes = Prime.each.lazy
    next_prime = nil
  
    primes.each do |prime|
      if prime > n
        next_prime = prime
        break
      end
    end
  
    next_prime
  end
end