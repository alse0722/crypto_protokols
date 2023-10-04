class Methods

    def initialize(params = {})
        @debug_mode = params.dig(:debug_mode)
    end

    def gen_random_int(length = 0)

        raise 'Not enough number length!' if length == 0

        # srand(Time.now.to_f)
        
        bin_str = ''
        num = 0

        while num == 0
            length.times do 
                # srand(Time.now.to_f)
                bin_str += rand(2).to_s
            end

            num = bin_str.to_i(2)
        end

        if @debug_mode
            puts %{\n\t[RAND] Generating random int:}
            sleep 0.2
            puts %{\t[BIN] #{bin_str}\n\t[INT] #{num}}
        end

        num
    end

    def is_prime(number = 0)
        test = ("1" * number) !~ /^1?$|^(11+?)\1+$/

        puts %{\t[PRIME?] Test for #{number} is prime: #{test}} if @debug_mode && number != 0
        test
    end

    def powm(key = 0, degree, md)
        raise 'Empty key!' if key == 0

        result = 1

        degree.times do |e|
            result = (result * key) % md
        end

        puts %{\n\t[POW] pow(#{key}, #{degree}) mod #{md} = #{result}} if @debug_mode

        result
    end


end