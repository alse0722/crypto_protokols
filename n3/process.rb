require './shamir.rb'

puts "\nEnter bin length"
lng = gets.strip.to_i

puts "\nEnter Alice's message:"
message = gets.strip.to_s

puts "\nEnter debug_mode type"
debug_mode = gets.strip.to_s

params = {
  bit_length: lng,
  debug_mode: debug_mode != '' ? debug_mode : 'by_step',
  message: message,
  int_gen_type: :alt
}

shamir = Shamir.new(params)

shamir.step0
shamir.step1
shamir.step2
shamir.step3
shamir.step4
