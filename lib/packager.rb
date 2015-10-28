require 'zip'
require 'base64'

module Jarbs
  class Packager
    def initialize(name, src_dir)
      @name = name
      @src_dir = src_dir
    end

    def package
      zipname = "#{@name}.zip"

      say "Packaging the following files:"

      stream = Zip::OutputStream.write_buffer do |out|
        contents.each do |filename|
          basefn = File.basename(filename)
          say basefn

          out.put_next_entry(basefn)
          out.write File.read(filename)
        end
      end

      # return the generated zip data
      stream.string
    end

    def delete
      File.delete "#{@name}.zip"
    end

    def contents
      path = File.join @src_dir, "**", "*.js"

      Dir.glob(path)
    end
  end
end
