require './methods.rb'
require 'securerandom'

class Steps
  def initialize()
    @alice = nil
    @bob = nil
  end

  def step0
    puts "\nSTEP 0 - Adding & Generation of start params"

    puts "\nEnter p bit length"
    @p_bit_length = gets.strip.to_i

    puts "\nEnter q bit length"
    @q_bit_length = gets.strip.to_i

    puts "\nEnter t parameter"
    @t = gets.strip.to_i

    params = {
      p_bit_length: @p_bit_length,
      q_bit_length: @q_bit_length,
      t: @t,
      debug_mode: :all
    }

    @methods = Methods.new(params)

    @alice = {name: 'Alice', send:[], get:[], calc:[]}.merge(@methods.make_keys('Alice'))
    @bob = {name:'Bob', send:[], get:[], calc:[]}.merge(@methods.make_keys('Bob'))

    pp @alice
    puts "\n"
    pp @bob
  end

  def step1
    puts "\nSTEP 1 - Alice send x value to Bob"

    @alice[:send] << make_msg(@alice[:name], {x: @alice[:prep][:x]})
    @bob[:get] << @alice[:send].last
    @bob[:process][:x] = @bob[:get].last[:msg][:x]

    pp @alice
    puts "\n"
    pp @bob
  end

  def step2
    puts "\nSTEP 2 - Bob generates 0 <= e <= 2^t - 1, sends e to Alice"

    @bob[:process][:e] = gen_e

    @bob[:send] << make_msg(@bob[:name], {e: @bob[:process][:e]})
    @alice[:get] << @bob[:send].last
    @alice[:process][:e] = @alice[:get].last[:msg][:e]

    pp @alice
    puts "\n"
    pp @bob
  end

  def step3
    puts "\nSTEP 3 - Alice calculates s = r + we, sends s to Bob"

    @alice[:process][:s] = find_s(@alice)

    @alice[:send] << make_msg(@alice[:name], {s: @alice[:process][:s]})
    @bob[:get] << @alice[:send].last
    @bob[:process][:s] = @bob[:get].last[:msg][:s]

    pp @alice
    puts "\n"
    pp @bob
  end


  def step4
    puts "\nSTEP 4 - Bob calculates z = g^s * y^e mod p, validates it with Alice's x"

    @bob[:process][:z] = client_b_check_x(@alice, @bob)

    pp @alice
    puts "\n"
    pp @bob

    puts "\nBob checks owned x and calculated x:"
    puts "\tGot from Alice: #{@bob[:process][:x]}"
    puts "\tCalculated val: #{@bob[:process][:z]}"

    puts "\nResult is:"
    puts (@bob[:process][:x] == @bob[:process][:z] ? "\tALL GOOD" : "\tSOMETHING GONE WRONG")
  end

  private

  def make_msg(src, msg)
    {
      # uid:  SecureRandom.uuid,
      # time: Time.now,
      src:  src,
      msg:  msg
    }
  end

  def gen_e
    return rand(2 ** @t)
  end

  def find_s(client)
    return (client[:prep][:r] + client[:secret_key][:w] * client[:process][:e]) % client[:open_key][:q]
  end

  def client_b_check_x(client_a, client_b)
    (client_a[:open_key][:g].pow(client_b[:process][:s], client_a[:open_key][:p]) * 
    client_a[:open_key][:y].pow(client_b[:process][:e], client_a[:open_key][:p])) % client_a[:open_key][:p]
  end
end