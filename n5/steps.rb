require 'prime'
require 'openssl'
require 'securerandom'

class Steps
  def initialize(params = {})
    @debug_mode = params.dig(:debug_mode)
    @bit_length = params.dig(:bit_length)
  end

  def step0
    puts "\nГенерация общих параметров."
  
    gen_close_params
    puts "\n#{@close_params}"

    gen_open_params
    puts "\n#{@open_params}"
  end

  def step1
    puts "\nГенерация индивидуальных параметров."
    phi_n = ez_mult(@close_params[:p] - 1, @close_params[:q] - 1)

    e = generate_coprime_number(phi_n)

    big_j = generate_coprime_bitstring(@open_params[:n])

    s = mod_pow_inverse(e, 1, phi_n)

    x = mod_pow_inverse(big_j.to_i(2), s, @open_params[:n])

    y = x.pow(e, @open_params[:n])

    @all_params = {
      closed: @close_params,
      opened: @open_params,
      phi_n: phi_n,
      j: big_j,
      s: s,
      x: x,
      y: y
    }

    @open_key = {
      n: @open_params[:n],
      e: e,
      y: y
    }

    @secret_key = {
      x: x
    }

    @all_params.merge!(
      {
        open_key: @open_key,
        secret_key: @secret_key
      }
    )

    puts "\nПараметры системы:"
    pp @all_params
  end

  def step2
    puts "\nСхема аутентификации Гиллу-Кискате"

    @alice = {name: "@alice", get: [], send:[], processed: {}}
    @bob = {name: "@bob", get: [], send:[], processed: {}}

    puts "\nКлиент #{@alice[:name]}: #{@alice}" if @debug_mode
    puts "Клиент #{@bob[:name]}: #{@bob}\n" if @debug_mode

    puts "\nA → B: {a} , где a = r^e mod n, r — случайное число Алисы, 1 ≤ r ≤ n – 1"
    r = rand(1..(@open_key[:n]))
    a = r.pow(@open_key[:e], @open_key[:n])
    @alice[:send] << {a: a}
    @bob[:get] << @alice[:send].last
    @bob[:processed].merge!(@bob[:get].last)
    @alice[:processed].merge!(@alice[:send].last)
    @alice[:processed].merge!({r: r})

    puts "\nКлиент #{@alice[:name]}: #{@alice}" if @debug_mode
    puts "Клиент #{@bob[:name]}: #{@bob}\n" if @debug_mode

    puts "\nB → A: {c}, где c — случайное число Боба, 0 ≤ c ≤ e – 1"
    c = rand(0..(@open_key[:e]-1))
    @bob[:send] << {c: c}
    @alice[:get] << @bob[:send].last
    @alice[:processed].merge!(@alice[:get].last)
    @bob[:processed].merge!(@bob[:send].last)

    puts "\nКлиент #{@alice[:name]}: #{@alice}" if @debug_mode
    puts "Клиент #{@bob[:name]}: #{@bob}\n" if @debug_mode

    puts "\nA → B: {z}, где z = r⋅x^c mod п"
    z = r * @secret_key[:x].pow(@alice[:processed][:c]) % @open_key[:n]
    @alice[:send] << {z: z}
    @bob[:get] << @alice[:send].last
    @bob[:processed].merge!(@bob[:get].last)
    @alice[:processed].merge!(@alice[:send].last)

    puts "\nКлиент #{@alice[:name]}: #{@alice}" if @debug_mode
    puts "Клиент #{@bob[:name]}: #{@bob}\n" if @debug_mode

    puts "\nB: Боб проверяет, что z^e = a·у^c mod n"
    puts "left: #{@bob[:processed][:z].pow(@open_key[:e]) % @open_key[:n]}" if @debug_mode
    puts "right: #{(@bob[:processed][:a]*@open_key[:y].pow(@bob[:processed][:c]) % @open_key[:n])}" if @debug_mode

    checkout = (
      (@bob[:processed][:z].pow(@open_key[:e]) % @open_key[:n]) == 
      (@bob[:processed][:a]*@open_key[:y].pow(@bob[:processed][:c]) % @open_key[:n])
    )

    puts "\nПараметры системы:" if @debug_mode
    pp @all_params if @debug_mode
    puts "\nКлиент #{@alice[:name]}: #{@alice}" if @debug_mode
    puts "Клиент #{@bob[:name]}: #{@bob}\n" if @debug_mode

    puts "\nРезультат проверки: " + (checkout ? "Проверка пройдена" : "Проверка не пройдена")
  end

  def step3
    puts "\nСхема подписи"
    pp @alice
    pp @bob
    pp @open_key
    pp @secret_key
    puts "\nВведите сообщение"
    message = gets.strip.to_s
    a = @alice[:processed][:r].pow(@open_key[:e], @open_key[:n])
    d = one_way_hash(message + a.to_s) % @open_key[:e]
    z = (@alice[:processed][:r] * @secret_key[:x]).pow(d, @open_key[:n])

    @alice[:send] << {m: message, d: d, z: z, y: @open_key[:y]}
    @bob[:get] << @alice[:send].last
    @bob[:processed].merge!(@bob[:get].last)
    @alice[:processed].merge!(@alice[:send].last)
    
    a_new = z.pow(@open_key[:e], @open_key[:n]) * @open_key[:y].pow(d, @open_key[:n])
    d_new = one_way_hash(message + a_new.to_s) % @open_key[:e]
    
    checkout = d = d_new
    puts "Исходный параметр d: #{d}"
    puts "Вычисленный параметр d_new: #{d_new}"
    puts "\nРезультат проверки: " + (checkout ? "Проверка пройдена" : "Проверка не пройдена")
    pp @alice
    pp @bob
  end

  private

  def one_way_hash(data)
    sha256 = OpenSSL::Digest::SHA256.new
    hashed_data = sha256.digest(data)

    hashed_data.unpack('H*')[0].to_i(16)
  end

  def mod_pow_inverse(x, a, n)
    raise ArgumentError, "n should be greater than 1" if n <= 1
    raise ArgumentError, "a should be a non-negative integer" if a < 0
  
    result = 1
    base = x % n
  
    while a > 0
      result = (result * base) % n if a.odd?
      base = (base * base) % n
      a /= 2
    end
  
    result
  end

  def mod_inverse(a, m)
    m0, x0, x1 = m, 0, 1
    while a > 1
      q = a / m
      m, a = a % m, m
      x0, x1 = x1 - q * x0, x0
    end
  
    x1 += m0 if x1 < 0
    x1
  end

  def generate_coprime_number(n)
    raise ArgumentError, "n should be greater than 1" if n <= 1
  
    # Генерируем случайное число
    random_number = rand(2..n-1)
  
    # Проверяем взаимную простоту с n
    until random_number.gcd(n) == 1
      random_number = rand(2..n-1)
    end
  
    return random_number
  end

  def generate_coprime_bitstring(n)
    raise ArgumentError, "n should be greater than 1" if n <= 1
  
    # Генерируем случайную битовую строку
    random_bitstring = rand(2**@bit_length).to_s(2)
  
    # Проверяем взаимную простоту с n
    until random_bitstring.to_i.gcd(n) == 1
      random_bitstring = rand(2**@bit_length).to_s(2)
    end
  
    return random_bitstring
  end

  def gen_close_params
    @close_params = {
      p: gen_big_num(@bit_length),
      q: gen_big_num(@bit_length)
    }
  end

  def gen_open_params
    @open_params = {
      n: ez_mult(@close_params[:p], @close_params[:q])
    }
  end

  def gen_big_num(bit_length = 15)
    raise ArgumentError, "Bit length should be greater than 0" if bit_length <= 0

    # Генерируем случайное число с использованием SecureRandom
    random_number = SecureRandom.random_number(2**bit_length)

    return random_number
  end

  def ez_mult(x, y)
    # Базовый случай: если числа состоят из одной цифры
    return x * y if x < 10 || y < 10
  
    # Находим количество цифр в числах
    m = [x.to_s.length, y.to_s.length].max
    m2 = (m / 2).to_i
  
    # Разбиваем числа на две части
    high1, low1 = x.divmod(10**m2)
    high2, low2 = y.divmod(10**m2)
  
    # Рекурсивно вычисляем три произведения
    z0 = ez_mult(low1, low2)
    z1 = ez_mult((low1 + high1), (low2 + high2))
    z2 = ez_mult(high1, high2)
  
    # Применяем формулу Карацубы для вычисления конечного результата
    return (z2 * 10**(2 * m2)) + ((z1 - z2 - z0) * 10**m2) + z0
  end

  def verify_signature(message, signature)
    a = @open_key[:n].pow(@open_key[:e], @open_key[:n])
    z = @secret_key[:x].pow(Integer(signature, 16), @open_key[:n])
  
    expected_hash = one_way_hash(message + a.to_s + @all_params[:s].to_s)
  
    return z == expected_hash.to_i(16)
  end
end