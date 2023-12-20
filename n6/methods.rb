class Methods
  def initialize(params = {})
    @debug_mode = params.dig(:debug_mode)
  end

  def gcd(a,b)
    puts "using default gcd(#{a}, #{b})" if @debug_mode
    while b != 0
      remainder = a % b
      a = b
      b = remainder
      #debug
      sleep 0.5 if @debug_mode 
      puts "gcd(#{a}, #{b})" if @debug_mode
    end

    return a 
  end

  def gcd_bin(a,b)
    puts "using binary gcd(#{a}, #{b})" if @debug_mode

    shift = 0

    while a != b
      if a % 2 == 0 && b % 2 == 0
        a = a / 2
        b = b / 2
        shift += 1
      elsif a % 2 == 0
        a = a / 2
      elsif b % 2 == 0
        b = b / 2
      elsif a > b
        a = (a-b)/2
      else
        b = (b-a)/2
      end
      #debug
      sleep 0.5 if @debug_mode 
      puts "gcd(#{a}, #{b})" if @debug_mode
    end
    
    return a * (2 ** shift) 
  end

  def gcd_ext(a, b, first = true)
    puts "using extended gcd(#{a}, #{b})" if @debug_mode && first

    if a == 0
      return b, 0, 1
    else
      res, x, y = gcd_ext(b%a, a, false)
      #debug
      sleep 0.5 if @debug_mode
      puts "gcd(#{a}, #{b}); koeff: (#{x}, #{y})" if @debug_mode
      return res, y - (b / a) * x, x
    end
  end

  def inverse(a, md)
    puts %{using inverse of #{a} in #{md}} if @debug_mode
    gcd, x, _ = gcd_ext(a, md)
    puts %{gcd = #{gcd}, x = #{x}} if @debug_mode
    if gcd != 1
      raise "\nNo inverse element exists\n"
    else
      return x % md
    end
  end

  def chineese_reminder_theorem(coefficients = [], modulus = [])

    if coefficients.empty? || modulus.empty?
      raise "Not enough data!"
    end

    puts %{using chineese_reminder_theorem for #{coefficients} in #{modulus}} if @debug_mode
    x = 0
    fact = modulus.reduce(:*)

    coefficients.zip(modulus).each do |a, m|
      ci = fact / m
      ci_inv = inverse(ci, m)
      x += a * ci * ci_inv
    end
    
    x %= fact

    return {x:x, md: fact}
  end

  def exea(a, b)
    return [0, 1] if a % b == 0
    x, y = exea(b, a % b)
    [y, x - y * (a / b)]
  end
  
  def mult_row_to_num(row, num, field)
    row.map { |el| (el * num) % field }
  end
  
  def add_rows(row1, row2, field)
    row1.each_with_index.map { |el, i| (el + row2[i]) % field }
  end
  
  def del_zero_rows(matrix)
    matrix.reject! { |row| row.all?(&:zero?) }
  end
  
  def swap_columns(matrix, col)
    (col + 1...matrix[col].size - 1).each do |i|
      if matrix[col][i] != 0
        matrix.each { |row| row[col], row[i] = row[i], row[col] }
        return
      end
    end
  end
  
  def gauss(matrix, field)
    matrix.each_with_index do |row, i|
      swap_columns(matrix, i) if row[i] == 0
  
      rev_el = exea(row[i], field)[0]
      matrix[i] = mult_row_to_num(row, rev_el, field)
  
      matrix.each_with_index do |row2, j|
        next if i == j
        matrix[j] = add_rows(row2, mult_row_to_num(matrix[i], -row2[i], field), field)
      end
    end
  
    del_zero_rows(matrix)
  
    have_solution = !matrix.any? { |row| row.last != 0 && row.take(matrix.size).all?(&:zero?) }
  
    return matrix, have_solution
  end
  
  def get_matrix(matrix)
    matrix.each { |row| puts row.join(' ') }
  end
  
  def get_ans(input, field)
  
    matrix = input[0]
    boo = input[1]
  
    if !boo
      puts "\n[GAUSS] There are no solutions!"
      return
    end
  
    # puts "\nAllowed solution of the original system:"
    # matrix.each do |row|
    #   row.each_with_index do |el, j|
    #     if j == row.size - 2
    #       print "#{el}x#{j + 1} = "
    #     elsif j == row.size - 1
    #       puts el
    #     else
    #       print "#{el}x#{j + 1} + "
    #     end
    #   end
    # end
  
    puts "\n[GAUSS] General solution of the original system:"
    matrix.each_with_index do |row, i|
      print "x#{i + 1} = "
      (i + 1...row.size - 1).each do |j|
        if matrix[i][j] != 0
          matrix[i][j] = -matrix[i][j] + field
          print "#{matrix[i][j]}x#{j + 1} + "
        end
      end
      puts matrix[i].last
    end
  
    # print "\n[GAUSS] Free unknowns:"
    # vals = gets.chomp.split(' ').map(&:to_i)
    vals = [1]
    res = []
    matrix.each do |row|
      ans = 0
      (matrix.size...row.size - 1).each { |j| ans += vals[j - matrix.size] * row[j] }
      ans += row.last
      res << ans
    end
    res.concat(vals)
  
    # print "\n[GAUSS] Particular solution: ("
    fin = []
    res.each_with_index do |el, i|
      if i == res.size - 1
        fin << el % field
        # print "#{el % field})"
      else
        fin << el % field
        # print "#{el % field}, "
      end
    end
    return fin
  end

  

end