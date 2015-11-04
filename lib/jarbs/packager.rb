require 'zip'

module Jarbs
  class Packager
    include Commander::UI

    def initialize(function)
      @function = function
    end

    def package
      say_ok "Packaging..."

      stream = Zip::OutputStream.write_buffer do |out|
        @function.each_file do |filename, contents|
          out.put_next_entry(filename)
          out.write contents
        end
      end

      write_zip(stream.string) if $debug

      # return the generated zip data
      stream.string
    end

    def write_zip(data)
      zipname = File.join(@function.root_path, "#{@function.name}.zip")

      File.open(zipname, 'w') {|zip| zip.write(data) }
      say_warning "DEBUG: Output debug package to #{zipname}"
    end
  end
end
