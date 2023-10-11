require './needham_shroeder.rb'

params = {
  debug_mode: 'all',
  methods_params: {
    debug_mode: 'all',
    bin_length: 10
  }
}

ns = NeedhamShroeder.new(params)
# pp ns

ns.start