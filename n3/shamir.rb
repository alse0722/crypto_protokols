require './coder.rb'
require 'prime'
require 'securerandom'

class Shamir
  def initialize(params = {})
    @debug_mode = params.dig(:debug_mode).to_sym
    @bit_length = params.dig(:bit_length).to_i
    @message = params.dig(:message)
  end

  def start
  end

  def step0
    puts "\n\n-----------------[STEP 0]-----------------\n\n"

    prime = gen_large_p

    @alice = make_client('Alice', prime)
    @bob = make_client('Bob', prime)

    puts "\nАлиса и Боб договариваются о большом простом числе P, таком, что:"
    puts "\t! P-1 имеет большой простой множитель\n\tP = #{prime}"
    puts "\nАлиса и Боб независимо выбирают числа a и b такие, что:"
    puts "\t! НОД(a, p - 1) == 1\n\t! a * b == 1 (mod p - 1)"
    puts "\tАлиса: #{@alice[:coder].get_params}\n\tБоб: #{@bob[:coder].get_params}"
    

    if @debug_mode == :all
      puts "\nСостояние Алисы"
      pp @alice
      puts "\nСостояние Боба"
      pp @bob
    end

    gets if @debug_mode == :all || @debug_mode == :by_step

  end

  def step1
    puts "\n\n-----------------[STEP 1]-----------------\n\n"

    send_message(@alice, @bob, @alice[:coder].encode(@message))

    puts "Алиса шифрует исходное сообщение <<#{@message}>> по формуле E_a(M) = M^a (mod p)"
    puts "\nАлиса отправляет сообщение Бобу:\n\t#{@alice[:m_pushed][-1]}"

    if @debug_mode == :all
      puts "\nСостояние Алисы"
      pp @alice
      puts "\nСостояние Боба"
      pp @bob
    end

    gets if @debug_mode == :all || @debug_mode == :by_step

  end

  def step2
    puts "\n\n-----------------[STEP 2]-----------------\n\n"

    last_msg = @bob[:m_pulled][-1][:body]
    # puts last_msg
    send_message(@bob, @alice, @bob[:coder].encode(last_msg, :enc))

    puts "Боб получает сообщение Алисы:\n\t#{@bob[:m_pulled][-1]}"
    puts "\nБоб шифрует полученное от Алисы тело (:body) сообщения по формуле E_b(E_a(M)) = M^(ab) (mod p)"
    puts "\nБоб отправляет сообщение Алисе\n\t#{@bob[:m_pushed][-1]}"

    if @debug_mode == :all
      puts "\nСостояние Алисы"
      pp @alice
      puts "\nСостояние Боба"
      pp @bob
    end

    gets if @debug_mode == :all || @debug_mode == :by_step

  end

  def step3
    puts "\n\n-----------------[STEP 3]-----------------\n\n"
    
    @alice[:m_decoded] << process_mesage(@alice, :enc)
    send_message(@alice, @bob, @alice[:m_decoded][-1][:body])

    puts "Алиса получает сообщение Боба:\n\t#{@alice[:m_pulled][-1]}"
    puts "\nАлиса расшифровывает тело (:body) полученного сообщения по формуле D_a(M^(ab)) = (M^(ab))^a'"
    puts "\tи получает зашифрованный текст\t#{@alice[:m_decoded][-1][:body]}"
    puts "\nАлиса отправляет тело расшифрованного сообщения Бобу\n\t#{@alice[:m_pushed][-1]}"

    if @debug_mode == :all
      puts "\nСостояние Алисы"
      pp @alice
      puts "\nСостояние Боба"
      pp @bob
    end

    gets if @debug_mode == :all || @debug_mode == :by_step

  end

  def step4
    puts "\n\n-----------------[STEP 4]-----------------\n\n"

    @bob[:m_decoded] << process_mesage(@bob, :raw)

    puts "Боб получает сообщение Алисы:\n\t#{@bob[:m_pulled][-1]}"
    puts "\nБоб расшифровывает тело (:body) полученного сообщения по формуле D_b(M^b) = M"
    puts "\tи получает исходное сообщение Алисы: <<#{@bob[:m_decoded][-1][:body]}>>"
    
    if @debug_mode == :all
      puts "\nСостояние Алисы"
      pp @alice
      puts "\nСостояние Боба"
      pp @bob
    end

    gets if @debug_mode == :all || @debug_mode == :by_step

    if @debug_mode == :by_step
      puts "\nСостояние Алисы"
      pp @alice
      puts "\nСостояние Боба"
      pp @bob
    end
  end

  private

  def make_client(name = '', p)
    {
      p: p,
      name: name,
      coder: Coder.new({p: p, bit_length: @bit_length}),
      m_pushed: [],
      m_pulled: [],
      m_decoded: []
    }
  end

  def send_message(src, dst, m)
    message = {
      src: src[:name],
      dst: dst[:name],
      uid: SecureRandom.uuid,
      body: m
    }

    src[:m_pushed] << message
    dst[:m_pulled] << message
  end

  def process_mesage(client, type = :raw)
    last_message = client[:m_pulled][-1]
    
    {
      src: last_message[:src],
      dst: last_message[:dst],
      uid: last_message[:uid],
      body: client[:coder].decode(last_message[:body], type)
    }
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
end
