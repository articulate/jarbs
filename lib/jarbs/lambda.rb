require 'aws-sdk'
require 'rugged'

require 'jarbs/function_definition'
require 'jarbs/compiler'
require 'jarbs/node_build'
require 'jarbs/packager'

module Jarbs
  class Lambda
    include Commander::UI

    LAMBDA_NODE_VERSION = "0.10.36"

    def initialize(name)
      @name = name
      @client = Aws::Lambda::Client.new region: default_region
    end

    def generate
      # create dir
      Dir.mkdir @name

      package_manifest = {
        name: @name,
        version: '0.0.0',
        description: ask("Function description: "),
        author: `whoami`.chomp,
        repository: {
          type: "git",
          url: repo_url
        },
        license: "UNLICENSED",
        engines: {
          node: "0.10.36"
        },
        main: "index.js",
        scripts: {},
        dependencies: {
          "babel-runtime" => "^5.8.25"
        },
        devDependencies: {
          "aws-sdk" => "^2.2.12",
          "babel" => "^5.8.29"
        }
      }

      # generate manifest file
      File.open(File.join(@name, 'package.json'), 'w') do |f|
        f.write JSON.pretty_generate(package_manifest)
      end
    end

    def create(src_path, compile: true)
      data = prepare_for_aws(src_path, compile)

      role = ask("IAM role for function: ")

      @client.create_function function_name: @name,
        runtime: 'nodejs',
        handler: 'handler.handler',
        role: role,
        memory_size: 128,
        timeout: 10,
        code: { zip_file: data }
    end

    def update(src_path, compile: true)
      data = prepare_for_aws(src_path, compile)

      @client.update_function_code function_name: @name, zip_file: data
    end

    def delete
      res = @client.delete_function function_name: @name
      say_ok "Removed #{@name}." if res.successful?
    end

    private

    def repo_url
      Rugged::Repository.discover(".").remotes.first.url
    rescue Rugged::RepositoryError => e
      nil
    end

    def prepare_for_aws(src_path, compile)
      function = FunctionDefinition.new(@name, src_path)
      Compiler.new(function).run if compile
      NodeBuild.new(function).npm_install
      Packager.new(function).package
    end

    def default_region
      `aws configure get region`.chomp
    end
  end
end
