require './methods.rb'

@units = false

if @units 
    @len = 15
    @debug_mode = false
else
    puts %{Enable debug? y/n}
    @debug_mode = gets.strip == 'y'

    puts %{\nEnter binary length for prime number}
    @len = gets.strip.to_i
end

@methods = Methods.new({debug_mode: @debug_mode})

def get_prime

    first_num = 0

    while ! @methods.is_prime(first_num)
        first_num = @methods.gen_random_int(@len)
    end

    first_num
end

def get_int

    @methods.gen_random_int(@len)
end

def apply_gn
    puts %{\nAlice and Bob applying prime numbers(g, n)} if !@units
    open_keys = {g: @methods.find_primitive_root(get_prime), n: get_prime}
    puts %{\nApplied: (g,n) = (#{open_keys[:g]}, #{open_keys[:n]})} if !@units

    open_keys
end

def get_secret_number(client)

    own_secret = get_int

    puts %{\n#{client[:name]} forms own secret number: #{own_secret}} if !@units

    own_secret
end

def get_half_key(source, destination)

    half_key = @methods.powm(source[:g], source[:secret], source[:n])

    puts %{\n#{source[:name]} forms half-key: #{half_key}} if !@units
    puts %{#{destination[:name]} gets half-key from #{source[:name]} : #{half_key}} if !@units

    half_key
end

def enum_secret_key(client)
    puts %{\n#{client[:name]} calculates secret key} if !@units

    secret_key = @methods.powm(client[:half_key], client[:secret], client[:n])

    puts %{\n#{client[:name]}'s secret key: K = #{secret_key}} if !@units

    secret_key
end

def show_client(client)
    puts %{\n#{client[:name]}'s final state:} if !@units
    pp client
end

def diffie_hellman

    puts %{\n--- DIFFIE-HELLMAN STARTS ---\n} if !@units

    open_keys = apply_gn

    a_client = {name: 'Alice', g: open_keys[:g], n: open_keys[:n]}
    b_client = {name: 'Bob', g: open_keys[:g], n: open_keys[:n]}

    a_client[:secret] = get_secret_number(a_client)
    b_client[:secret] = get_secret_number(b_client)

    a_client[:half_key] = get_half_key(b_client, a_client)
    b_client[:half_key] = get_half_key(a_client, b_client)

    a_client[:secret_key] = enum_secret_key(a_client)
    b_client[:secret_key] = enum_secret_key(b_client)

    puts %{\n--- DIFFIE-HELLMAN ENDS ---\n} if !@units

    show_client(a_client) if !@units
    show_client(b_client) if !@units

    return a_client[:secret_key] == b_client[:secret_key] if @units
    
    puts
end

diffie_hellman