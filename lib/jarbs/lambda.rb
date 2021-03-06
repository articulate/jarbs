require 'aws-sdk'
require 'base64'

require 'jarbs/function_definition'
require 'jarbs/manifest_helpers'
require 'jarbs/project_generator'
require 'jarbs/function_generator'
require 'jarbs/node_build'
require 'jarbs/packager'

module Jarbs
  class Lambda
    include Commander::UI
    include CrashReporter::DSL

    attr_accessor :function

    def initialize(name, options)
      @options = options

      @function = FunctionDefinition.new(name, @options.env)

      credentials = Aws::SharedCredentials.new(profile_name: @options.profile)
      @client = Aws::Lambda::Client.new region: default_region, credentials: credentials
    end

    def generate
      FunctionGenerator.new(@function).generate
    end

    def prepare
      node = NodeBuild.new(@function)

      node.npm_build
      @package = Packager.new(@function).package
    ensure
      node.clean
    end

    def deploy
      deployed? ? update : create
    end

    def create
      role = @options[:role] || ask("IAM role for function: ")

      say "Creating #{@function.env_name} on Lambda..."

      capture_errors do
        @client.create_function function_name: @function.env_name,
                                runtime: 'nodejs',
                                handler: 'index.handler',
                                role: role,
                                memory_size: 128,
                                timeout: 10,
                                code: { zip_file: @package }
      end

      say_ok "Complete!"
    end

    def update
      say "Updating #{@function.env_name} on Lambda..."

      capture_errors do
        @client.update_function_code function_name: @function.env_name,
                                     zip_file: @package
      end

      say_ok "Complete!"
    end

    def delete
      res = @client.delete_function function_name: @function.env_name
      say_ok "Removed #{@function.env_name}." if res.successful?
    end

    def info
      @client.get_function(function_name: @function.env_name)
    end

    def invoke(payload="")
      payload = JSON.generate(payload) unless payload.is_a? String

      say "Invoking with:\n\n#{payload}\n\n"

      capture_errors do
        resp = @client.invoke function_name: @function.env_name,
                              log_type: 'Tail',
                              payload: payload


        if resp.successful?
          say_ok Base64.decode64(resp.data.log_result)
        else
          say_error resp.error.message
        end
      end
    end

    def deployed?
      true if info
    rescue Aws::Lambda::Errors::ResourceNotFoundException => e
      false
    end

    def exists?
      Dir.exists? function.source_path
    end

    private

    def default_region
      `aws configure get region`.chomp
    end
  end
end
