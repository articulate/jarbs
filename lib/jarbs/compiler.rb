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

        write_compiled(file, compiled_info['code']) if $debug
      end

      say_warning "DEBUG: Compiled source output to #{@function.debug_path}" if $debug
    end

    private


    def write_compiled(file, src)
      debug_file_path = File.join(@function.debug_path, file)
      root_dir_path = File.dirname(debug_file_path)

      FileUtils.mkdir_p root_dir_path unless Dir.exists? root_dir_path
      File.open(debug_file_path, 'w') do |debug_out|
        debug_out.write(src)
      end
    end
  end
end
