require 'babel/transpiler'

module Jarbs
  class Compiler
    include Commander::UI

    def initialize(function)
      @function = function
    end

    def run
      say_ok "Compiling..."

      @function.each_file do |file, source|
        compiled_info = Babel::Transpiler.transform source
        @function.update(file, compiled_info['code'])
      end
    end
  end
end
