require 'prime'
require 'openssl'

class Keygen

def initialize

end

def gen_keys
  # Шаг 1: Генерация простого числа p (битовая длина 1024)
  p = Prime.each(2**(1024-1), 2**1024 - 1).first
  puts p
  # Шаг 2: Генерация простого числа q (битовый размер 160 битов)
  q = Prime.each(2**(160-1), 2**160 - 1).first
  puts q
  # Шаг 3: Генерация случайного числа g, такого что g^q = 1 (mod p)
  g = find_random_g(p, q)
  puts g
  # Шаг 4: Генерация случайного числа w < q
  w = SecureRandom.random_number(q)
  puts w
  # Шаг 5: Вычисление y = g^(q-w) (mod p)
  y = g.mod_pow(q - w, p)
  puts y
  # Шаг 6: Сохранение ключей
  open_key = { p: p, q: q, g: g, y: y }
  private_key = { w: w }

  {open_key: open_key, private_key: private_key}
end

private

def find_random_g(p, q)
  loop do
    g = SecureRandom.random_number(p-2) + 2
    return g if g.mod_pow(q, p) == 1
  end
end

end