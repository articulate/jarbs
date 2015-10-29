module Jarbs
  class FunctionDefinition
    attr_reader :name, :source_path

    IGNORE = [
      "debug/",
      "package.json",
      "node_modules/"
    ]

    def initialize(name, source_path)
      @name = name
      @source_path = source_path
    end

    def manifest
      @manifest ||= JSON.parse File.read(File.join(source_path, 'package.json'))
    end

    def files
      path = File.join source_path, "**", "*.js"

      # return without possible debug dir
      Dir.glob(path).reject do |file|
        IGNORE.any? {|ignore| file.start_with? File.join(@source_path, ignore) }
      end
    end

    def sources
      @sources ||= {}
      return @sources unless @sources.empty?

      files.each {|f| update(basename(f), File.read(f)) }
      @sources
    end

    def includes
      path = File.join source_path, "**", "*"
      resources = Dir.glob(path, File::FNM_DOTMATCH).reject {|f| File.directory? f } - files

      resources.map {|f| basename(f) }
    end

    def update(source_name, src)
      @sources[source_name] = src
    end

    def each_file(&block)
      sources.each {|path, source| yield path, source }
    end

    def source_of(file)
      File.read(file)
    end

    def debug_path
      File.join(source_path, 'debug')
    end

    def basename(filename)
      filename.gsub(@source_path + '/', '')
    end

  end
end
