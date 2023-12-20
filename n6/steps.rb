require 'matrix'
require './methods.rb'

class Steps
  def initialize(params = {})
    params.dig(:debug_mode)
  end

  def step0
    puts "Введите размер поля:"
    @p = gets.strip.to_i
    puts "Ведедите секрет s (s < p):"
    @s = gets.strip.to_i
    puts "Введите количество сторон n_max:"
    @n_max = gets.strip.to_i
    puts "Введите количество сторон, необходимых для восстановления секрета n_min:"
    @n_min = gets.strip.to_i
    puts "Реализуем (#{@n_min},#{@n_max})-пороговое разделение ключа #{@s}!"

    @iv = [@s]
    (@n_min-1).times {@iv << gen_rand_nuber}
    puts "Задали ключевую точку iv:#{@iv}"

    @clients = []
    num = 1
    @n_max.times do
      ownv = [] 
      @n_min.times {ownv << gen_rand_nuber}
      ownv << gen_d(@iv, ownv)
      @clients << {id: num, ownv: ownv}
      num += 1
    end 
    puts "Сформированы следующие клиенты:"
    @clients.each {|client| puts client}
  end

  def step1
    puts "\nПроверим восстановление секрета"
    ans = :y
    while ans == :y
      puts "\nВведите id клиентов для восстановления секрета (n1 n2 ...):"
      ids = gets.split.map(&:to_i)
      
      matrix = []
      ids.each do |id|
        @clients.each do |client|
          matrix << client[:ownv] if client[:id] == id
          puts "Выбран клиент: #{client}" if client[:id] == id && @debug_mode
        end
      end

      puts "Для восстановления секрета данными клиентами необходимо решить систему:"
      matrix.each do |line|
        str = "| ( "
        line[0..-2].each_with_index do |ai, i|
          str << "#{ai} * x#{i + 1} + "
        end
        str << "#{line[-1]} ) mod #{@p} = 0"
        puts str
        # line << 0
      end

      puts "Матрица выглядит следующим образом:"
      pp matrix

      puts "Решим систему методом Гаусса:"
      new_iv = solve_gauss_system(matrix)

      puts "Проверим правильность полученного ключа:"
      all_good = true
      @iv.each_with_index do |a, i|
        puts "iv[#{i}]: #{a},\tnew_iv[#{i}]: #{new_iv[i]}"
        all_good &= a == new_iv[i]
      end
      puts "\nПроверка ключа #{all_good ? "пройдена!" : "НЕ пройдена!"}"
      
      puts "\nВыбрать других клиентов? [y,n]"
      ans = gets.strip.to_sym
    end
  end

  private

  def gen_rand_nuber
    return rand(@p)
  end

  def gen_d(iv, ownv)
    d = 0
    
    iv.each_with_index do |a, i|
      d += a * ownv[i]
    end

    d = (-d % @p)
  end

  def solve_gauss_system(matrix)
    @methods = Methods.new({debug_mode: @debug_mode})
    field = @p
    
    matrix.each do |line|
      line[-1] = (@p - line[-1]) % @p
    end
    # pp matrix

    rows, cols = matrix.size, @n_min + 1
  
    triangular, status = @methods.gauss(matrix, field)
    puts "\n[GAUSS] Triangular matrix: "
    @methods.get_matrix(matrix)
    result = @methods.get_ans([matrix, status], field) 
    return result
  end
end
