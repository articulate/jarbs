require 'aws-sdk'

require 'jarbs/function_definition'
require 'jarbs/manifest_helpers'
require 'jarbs/project_generator'
require 'jarbs/function_generator'
require 'jarbs/node_build'
require 'jarbs/packager'

module Jarbs
  class Lambda
    include Commander::UI

    def initialize(name, options)
      @options = options

      @function = FunctionDefinition.new(name, @options.env)
      @client = Aws::Lambda::Client.new region: default_region
    end

    def generate
      FunctionGenerator.new(@function).generate
    end

    def create
      data = prepare_for_aws
      role = @options[:role] || ask("IAM role for function: ")

      say "Deploying #{@function.env_name} to Lambda..."
      @client.create_function function_name: @function.env_name,
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

      say "Updating #{@function.env_name} on Lambda..."
      @client.update_function_code function_name: @function.env_name, zip_file: data
      say_ok "Complete!"
    end

    def delete
      res = @client.delete_function function_name: @function.env_name
      say_ok "Removed #{@function.env_name}." if res.successful?
    end

    private

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
