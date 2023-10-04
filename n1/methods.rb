class Methods

    def initialize(params = {})
        @debug_mode = params.dig(:debug_mode)
    end

    def gen_random_int(length = 0)

        raise 'Not enough number length!' if length == 0

        bin_str = ''
        num = 0

        while num == 0
            length.times do 
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

    def find_factors(n)
        factors = []
        (2..Math.sqrt(n).to_i).each do |i|
            while n % i == 0
                factors << i
                n /= i
            end
        end
        if n > 1
            factors << n
        end
        
        return factors.uniq
    end

    def find_primitive_root(p)
        if !is_prime(p)
            return nil
        end
      
        phi = p - 1
        factors = find_factors(phi)
      
        (2...p).each do |g|
            is_primitive_root = true

            factors.each do |factor|
                if g.pow(phi / factor, p) == 1
                    is_primitive_root = false
                    break
                end
            end
            if is_primitive_root
                return g
            end
        end
      
        return nil
    end


end

# puts Methods.new(debug_mode: true).find_primitive_root(23)