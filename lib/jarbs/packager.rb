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
        @function.each_file do |filename, source|
          out.put_next_entry(filename)
          out.write source
        end

        @function.includes.each do |file|
          out.put_next_entry(file)
          out.write File.read(File.join(@function.source_path, file))
        end
      end

      # TODO: save zip to FS if --debug
      write_zip(stream.string) if $debug

      # return the generated zip data
      stream.string
    end

    def write_zip(data)
      zipname = "#{@function.name}.zip"

      File.open(zipname, 'w') {|zip| zip.write(data) }
      say_warning "DEBUG: Output debug package to #{zipname}"
    end

    def delete
      File.delete "#{@function.name}.zip"
    end
  end
end
