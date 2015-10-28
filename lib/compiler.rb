require 'babel/transpiler'

module Jarbs
  class Compiler
    include Commander::UI

    def initialize(source)
      @source = source
    end

    def run
      files = {}

      say_ok "Compiling..."

      contents.each do |file|
        root_path = basename(file)

        compiled_info = Babel::Transpiler.transform File.read(file)
        files[root_path] = compiled_info['code']

        write_compiled(root_path, compiled_info['code']) if $debug
      end

      say_warning "DEBUG: Compiled source output to #{debug_path}" if $debug

      files
    end

    private

    def debug_path
      File.join(@source, 'debug')
    end

    def write_compiled(file, src)
      debug_file_path = File.join(debug_path, file)
      root_dir_path = File.dirname(debug_file_path)

      FileUtils.mkdir_p root_dir_path unless Dir.exists? root_dir_path
      File.open(debug_file_path, 'w') do |debug_out|
        debug_out.write(src)
      end
    end

    def basename(filename)
      filename.gsub(@source + '/', '')
    end

    def contents
      path = File.join @source, "**", "*.js"

      # return without possible debug dir
      Dir.glob(path).reject {|f| f.start_with? debug_path }
    end
  end
end
