module Jarbs
  class FunctionDefinition
    attr_reader :name, :root_path

    def initialize(name, root_path, env)
      @name = name
      @root_path = root_path || name
    end

    def manifest
      @manifest ||= JSON.parse File.read(manifest_file)
    end

    def manifest_file
      File.join(root_path, 'package.json')
    end

    def files
      path = File.join build_path, "**", "*"
      Dir.glob(path, File::FNM_DOTMATCH)
          .reject {|f| File.directory? f }
    end

    def each_file(&block)
      files.each {|file| yield basename(file), File.read(file) }
    end

    def build_path
      File.join(root_path, 'dest')
    end

    def source_path
      File.join(root_path, 'src')
    end

    def basename(filename)
      filename.gsub(build_path + '/', '')
    end
  end
end
