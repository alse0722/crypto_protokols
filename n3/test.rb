def encrypt(str, a, p)
  encrypted_text = str.chars.map do |char|
    char_code = char.ord
    char_code = char_code % p  # Ограничиваем char_code значением p
    encrypted_char_code = (char_code ** a) % p
    encrypted_char_code.chr
  end.join
end

def decrypt(encrypted_str, a, p)
  decrypted_text = encrypted_str.chars.map do |char|
    encrypted_char_code = char.ord
    decrypted_char_code = (encrypted_char_code ** a) % p
    decrypted_char_code.chr
  end.join
end

# Пример использования
str = "Hello, World!"
a = 17
p = 97