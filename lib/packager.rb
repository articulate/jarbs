require 'zip'

module Jarbs
  class Packager
    include Commander::UI

    def initialize(name, source_files)
      @name = name
      @source_files = source_files
    end

    def package
      say_ok "Packaging..."

      stream = Zip::OutputStream.write_buffer do |out|
        @source_files.each do |filename, source|
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
