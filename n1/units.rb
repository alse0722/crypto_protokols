require './proc.rb'

def unit_test

    success_tries = 0
    failure_tries = 0
    total_tries = 0

    puts %{Enter tests count:}
    n = gets.strip.to_i

    n.times do
        diffie_hellman

        total_tries += 1
        if diffie_hellman
            success_tries += 1
        else
            failure_tries += 0
        end
    end

    puts %{STAT:\n\ttotal: #{total_tries}\n\tsuccess: #{success_tries}\n\tfail: #{failure_tries}}

end

unit_test