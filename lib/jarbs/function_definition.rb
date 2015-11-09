require 'forwardable'

module Jarbs
  class FunctionDefinition
    extend Forwardable

    attr_reader :env, :name, :root_path
    def_delegators :manifest, :description

    def initialize(name, env='dev')
      @env = env
      @name = name
      @root_path = File.join('lambdas', name)
    end

    def exists?
      Dir.exists? root_path
    end

    def remove!
      FileUtils.rm_r root_path
    end

    def manifest
      @manifest ||= OpenStruct.new JSON.parse(File.read(manifest_file))
    end

    def manifest_file
      File.join(source_path, 'package.json')
    end

    def env_name
      "#{env}-#{name}"
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
