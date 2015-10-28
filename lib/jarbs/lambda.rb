require 'aws-sdk'

require 'jarbs/function_definition'
require 'jarbs/compiler'
require 'jarbs/packager'

module Jarbs
  class Lambda
    include Commander::UI

    def initialize(name)
      @name = name
      @client = Aws::Lambda::Client.new region: default_region
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

    def prepare_for_aws(src_path, compile)
      function = FunctionDefinition.new(@name, src_path)
      Compiler.new(function).run if compile
      Packager.new(@name, function).package
    end

    def default_region
      `aws configure get region`.chomp
    end
  end
end
