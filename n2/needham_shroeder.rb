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
    #Инициализация клиентов
    a_client = make_client('Alice')
    b_client = make_client('Bob')
    t_client = make_client('Trent')

    #по условию Алиса и Трент, Боб и Трент уже имеют общий ключ
    bt_session_key = SecureRandom.random_bytes(32)
    at_session_key = SecureRandom.random_bytes(32)

    a_client[:session_keys][t_client[:name].to_sym] = at_session_key
    t_client[:session_keys][a_client[:name].to_sym] = at_session_key

    b_client[:session_keys][t_client[:name].to_sym] = bt_session_key
    t_client[:session_keys][b_client[:name].to_sym] = bt_session_key

    # pp a_client
    # pp b_client
    # pp t_client

    #Алиса посылает сообщение тренту (A, B, R_a)
    msg = {
      name_a: a_client[:name],
      name_b: b_client[:name],
      random_a: a_client[:own_secret] 
    }

    send(a_client, t_client, msg, :encrypted)
    t_client[:decrypted] << process_pulled(t_client)

    puts "\n\nAFTER STEP 1\n\n"
    pp a_client
    puts
    pp t_client
    gets

    #Трент генерирует случайный ключ и посылает сообщение Алисе E_a(R_a, B, K, E_b(k, A))
    lst_msg = t_client[:decrypted][-1]
    
    puts "lst_msg"
    puts lst_msg

    new_key = gen_random_key

    puts "new_key"
    puts new_key

    body_to_b = {
      name_a: lst_msg[:src],
      k: new_key
    }

    msg_to_b = make_message(t_client, b_client, body_to_b, :encrypted)

    puts "msg_to_b"
    puts msg_to_b

    msg_to_a = {
      random_a: lst_msg[:random_a],
      k_to: lst_msg[:name_b],
      k: new_key,
      msg_b: make_message(t_client, b_client, msg_to_b, :encrypted)
    }

    puts "msg_to_a"
    puts msg_to_a

    send(t_client, a_client, msg_to_a, :encrypted)
    a_client[:decrypted] << process_pulled(a_client)

    puts "\n\nAFTER STEP 2\n\n"
    pp a_client
    pp t_client

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
        time: Time.now,
        body: enc_body
      }
    when :default
      {
        hdr: mode,
        src: src[:name],
        dst: dst[:name],
        uid: SecureRandom.uuid,
        time: Time.now,
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

  def process_pulled(client)

    packet = client[:pulled][-1]

    case packet[:hdr]
    when :encrypted
      # decrypt_key = client[:session_keys][packet[:src][:name].to_sym]
      # @encryptor.key = client[:session_keys][packet[:src].to_sym]
      # body = @encryptor.decrypt(packet[:body])
      
      body = decrypt_message(client[:session_keys][packet[:src].to_sym], packet[:body])
      {
        hdr: packet[:hdr],
        src: packet[:src],
        dst: packet[:dst],
        uid: packet[:uid],
        time: packet[:time],
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
    Base64.encode64(JSON.dump(hash)) # Convert hash to JSON string
  end
  
  def string_to_hash(string)
    JSON.parse(Base64.decode64(string)).transform_keys(&:to_sym)
  end

  def gen_random_key
    SecureRandom.random_bytes(32)
  end

end