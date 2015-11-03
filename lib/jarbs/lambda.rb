require 'aws-sdk'
require 'rugged'

require 'jarbs/function_definition'
require 'jarbs/node_build'
require 'jarbs/packager'

module Jarbs
  class Lambda
    include Commander::UI

    def initialize(name, options)
      @function = FunctionDefinition.new(name, options.dir, options.env)
      @options = options

      @client = Aws::Lambda::Client.new region: default_region
    end

    def generate
      say_ok "Generating function skeleton at #{@function.source_path}"
      Dir.mkdir_p @function.source_path

      package_manifest = {
        name: @function.name,
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
        scripts: {
            build: "babel --optional runtime --out-dir dest src",
        },
        dependencies: {
            'babel-runtime' => '< 6'
        },
        devDependencies: {
            'babel' => '< 6'
        }
      }

      # generate manifest file
      File.open(File.join(@function.root_path, 'package.json'), 'w') do |f|
        f.write JSON.pretty_generate(package_manifest)
      end

      # install base handler file
      FileUtils.cp File.join(File.dirname(__FILE__), 'fixtures', 'index.js'), @function.source_path

      # Install core NPM dependencies
      NodeBuild.new(@function).npm_install
    end

    def create
      data = prepare_for_aws

      role = ask("IAM role for function: ")

      say "Deploying #{@function.name} to Lambda..."
      @client.create_function function_name: @function.name,
        runtime: 'nodejs',
        handler: 'index.handler',
        role: role,
        memory_size: 128,
        timeout: 10,
        code: { zip_file: data }

      say_ok "Complete!"
    end

    def update
      data = prepare_for_aws

      say "Updating #{@function.name} on Lambda..."
      @client.update_function_code function_name: @function.name, zip_file: data
      say_ok "Complete!"
    end

    def delete
      res = @client.delete_function function_name: @function.name
      say_ok "Removed #{@function.name}." if res.successful?
    end

    private

    def repo_url
      Rugged::Repository.discover(".").remotes.first.url
    rescue Rugged::RepositoryError => e
      nil
    end

    def prepare_for_aws
      node = NodeBuild.new(@function)

      node.npm_build
      package = Packager.new(@function).package
    ensure
      node.clean
      package
    end

    def default_region
      `aws configure get region`.chomp
    end
  end
end
