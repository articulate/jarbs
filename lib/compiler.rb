require 'babel/transpiler'

module Jarbs
  class Compiler
    def initialize(source, output=nil)
      @source = source
      @output = output || File.join(source, "build")
    end

    def run
      Dir.mkdir @output unless Dir.exists? @output

      contents.each do |file|
        compiled = Babel::Transpiler.transform File.read(file)
        output_file = File.join @output, File.basename(file)

        File.open(output_file, 'w') {|out| out.write compiled['code'] }
      end

      @output
    end

    def clean
      FileUtils.rm_r @output
    end

    private

    def contents
      path = File.join @source, "**", "*.js"

      Dir.glob(path)
    end
  end
end
