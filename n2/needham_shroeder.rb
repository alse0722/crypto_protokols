require './methods.rb'
require 'encryption'
require './names.rb'
require 'securerandom'
require 'digest'
require 'json'

class NeedhamShroeder
  def initialize(params = {})
    @debug_mode = params.dig(:debug_mode).to_sym

    @methods = Methods.new(params.dig(:methods_params))
    
    @encryptor = Encryption::Symmetric.new
    @encryptor.iv = SecureRandom.random_bytes(16)
  end

  def start
    kk = gen_random_key

    #Инициализация клиентов
    a_client = make_client('Alice')
    b_client = make_client('Bob')
    t_client = make_client('Trent')

    #по условию Алиса и Трент, Боб и Трент уже имеют общий ключ
    bt_session_key = gen_random_key
    at_session_key = gen_random_key

    a_client[:session_keys][t_client[:name].to_sym] = at_session_key
    t_client[:session_keys][a_client[:name].to_sym] = at_session_key

    b_client[:session_keys][t_client[:name].to_sym] = bt_session_key
    t_client[:session_keys][b_client[:name].to_sym] = bt_session_key

    #Алиса посылает сообщение тренту (A, B, R_a)
    msg = {
      name_a: a_client[:name],
      name_b: b_client[:name],
      random_a: a_client[:own_secret] 
    }

    send(a_client, t_client, msg, :default)

    puts "\n\n\nNEEDHAM-SHROEDER STEP 1\n\n"
    puts "\nАлиса посылает сообщение тренту (A, B, R_a)"
    pp a_client[:pushed][-1]
    gets

    #Трент генерирует случайный ключ и посылает сообщение Алисе E_a(R_a, B, K, E_b(k, A))
    t_client[:decrypted] << process_pulled(t_client)

    lst_msg = t_client[:decrypted][-1][:body]
    
    new_key = "AB session key"

    body_to_b = {
      name_a: lst_msg[:name_a],
      k: new_key
    }

    @msg_to_b = make_message(t_client, b_client, body_to_b, :encrypted)

    msg_to_a = {
      random_a: lst_msg[:random_a],
      k_to: lst_msg[:name_b],
      k: new_key,
      msg_b: @msg_to_b.to_s
    }

    send(t_client, a_client, msg_to_a, :encrypted)
    a_client[:decrypted] << process_pulled(a_client)

    puts "\n\n\nNEEDHAM-SHROEDER STEP 2\n\n"
    puts "\nТрент получает сообщение от Алисы"
    pp t_client[:decrypted][-1]
    puts "\nТрент генерирует случайный ключ и посылает сообщение Алисе E_a(R_a, B, K, E_b(k, A))"
    pp t_client[:pushed][-1]
    gets

    #Алиса расшифровывает К, прверяет R_a и пересылает E_b(k, A) к В
    lst_msg = a_client[:decrypted][-1][:body]
    raise "R_a not matched! " if a_client[:own_secret] != lst_msg[:random_a]
    a_client[:session_keys][lst_msg[:k_to].to_sym] = kk
    a_client[:decrypted][-1][:body][:k] = kk
    
    send(a_client, b_client, lst_msg[:msg_b], :default)

    puts "\n\n\nNEEDHAM-SHROEDER STEP 3\n\n"
    puts "\nАлиса расшифровывает К, прверяет R_a"
    pp a_client[:decrypted][-1]
    puts "\nАлиса пересылает E_b(k, A) к В"
    pp a_client[:pushed][-1]
    gets

    #Боб извлекает К, шифрует с его помощью число и отправляет алисе 
    b_client[:decrypted] << process_pulled(b_client, :body)
    lst_msg = b_client[:decrypted][-1][:body]

    b_client[:decrypted][-1][:body][:k] = kk
    b_client[:session_keys][lst_msg[:name_a].to_sym] = kk

    msg = {
      random_b: b_client[:own_secret]
    }
    
    send(b_client, a_client, msg, :encrypted)


    puts "\n\n\nNEEDHAM-SHROEDER STEP 4\n\n"
    puts "\nБоб извлекает К"
    pp b_client[:decrypted][-1]
    puts "\nБоб шифрует с его помощью число #{b_client[:own_secret]} и отправляет Алисе"
    pp b_client[:pushed][-1]
    gets

    a_client[:decrypted] << process_pulled(a_client)
    number = a_client[:decrypted][-1][:body][:random_b]
    msg = {
      random_b: number - 1
    }

    send(a_client, b_client, msg, :encrypted)
    b_client[:decrypted] << process_pulled(b_client)

    puts "\n\n\nNEEDHAM-SHROEDER STEP 5\n\n"
    puts "\nАлиса получает сообщение, расшифровывает число Боба #{number}"
    pp a_client[:decrypted][-1]
    puts "\nАлиса отправляет назад зашифрованное ключом K число #{number - 1}"
    pp a_client[:pushed][-1]
    puts "\nБоб получает это число. Числа сходятся, все верно"
    pp b_client[:decrypted][-1]
    gets

    puts "\n\n[Alice final state]"
    pp a_client
    gets


    puts "\n\n[Bob final state]"
    pp b_client
    gets


    puts "\n\n[Trent final state]"
    pp t_client
    gets


    0
  end

  private

  def make_client(name = {})
    {
      name: name || NAMES.sample,
      pushed: [],
      pulled: [],
      decrypted: [],
      own_secret: SecureRandom.rand(10**16),
      session_keys: {}
    }
  end

  def make_message(src, dst, body, mode)
    case mode
    when :encrypted
      enc_key = src[:session_keys][dst[:name].to_sym]
      enc_body = encrypt_message(enc_key, body)
      {
        hdr: mode,
        src: src[:name],
        dst: dst[:name],
        uid: SecureRandom.uuid,
        # time: Time.now,
        body: enc_body
      }
    when :default
      {
        hdr: mode,
        src: src[:name],
        dst: dst[:name],
        uid: SecureRandom.uuid,
        # time: Time.now,
        body: body
      }
    else
      {
        hdr: :error
      }
    end
  end

  def send(src, dst, body, mode)
    src[:pushed] << make_message(src, dst, body, mode)
    dst[:pulled] << src[:pushed].last

    [src, dst]
  end

  def process_pulled(client, mode = :default)

    packet = (mode == :default) ? client[:pulled][-1] : @msg_to_b
    # pp packet
    case packet[:hdr]
    when :encrypted
      
      body = decrypt_message(client[:session_keys][packet[:src].to_sym], packet[:body])
      {
        hdr: packet[:hdr],
        src: packet[:src],
        dst: packet[:dst],
        uid: packet[:uid],
        # time: packet[:time],
        body: body
      }
    when :default
      packet
    else
      {
        hdr: :error_in_decryption
      }
    end
  end

  def encrypt_message(key, message)
    @encryptor.key = key
    @encryptor.encrypt (hash_to_string(message))
  end

  def decrypt_message(key, message)
    @encryptor.key = key
    string_to_hash(@encryptor.decrypt(message))
  end

  def hash_to_string(hash)
    # pp hash
    JSON.dump(hash)
  end
  
  def string_to_hash(string)
    JSON.parse(string).transform_keys(&:to_sym)
  end

  def gen_random_key
    SecureRandom.random_bytes(32)
  end

end
