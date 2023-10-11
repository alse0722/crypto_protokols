class Methods
  def initialize(params = {})
    @debug_mode = params.dig(:debug_mode).to_sym
    @bin_length = params.dig(:bin_length).to_i
  end
  
  def gen_random_int()

    raise 'Not enough number length!' if @bin_length == 0

    bin_str = '1'

    (@bin_length - 1).times do 
      bin_str += rand(2).to_s
    end

    num = bin_str.to_i(2)

    if @debug_mode == :all
      puts %{\n\t[RAND] Generating random int:}
      sleep 0.5
      puts %{\t[BIN] #{bin_str}\n\t[INT] #{num}}
    end

    num
  end



end