require 'zip'

module Jarbs
  class Packager
    include Commander::UI

    def initialize(name, function)
      @name = name
      @function = function
    end

    def package
      say_ok "Packaging..."

      stream = Zip::OutputStream.write_buffer do |out|
        @function.each_file do |filename, source|
          out.put_next_entry(filename)
          out.write source
        end
      end

      # TODO: save zip to FS if --debug
      write_zip(stream.string) if $debug

      # return the generated zip data
      stream.string
    end

    def write_zip(data)
      zipname = "#{@name}.zip"

      File.open(zipname, 'w') {|zip| zip.write(data) }
      say_warning "DEBUG: Output debug package to #{zipname}"
    end

    def delete
      File.delete "#{@name}.zip"
    end
  end
end
