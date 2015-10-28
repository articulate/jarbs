require 'aws-sdk'
require 'base64'

require_relative 'compiler'
require_relative 'packager'

module Jarbs
  class Lambda
    include Commander::UI

    def initialize(name)
      @name = name
      @client = Aws::Lambda::Client.new region: default_region
    end

    def create(src_path)
      data = prepare_for_aws(src_path)

      @client.create_function function_name: @name,
        runtime: 'nodejs',
        handler: 'handler.handler',
        role: "arn:aws:iam::689543204258:role/dev-dumbo-r-IamRoleLambda-1MEDLE5CDO0KN",
        memory_size: 128,
        timeout: 10,
        code: { zip_file: data }
    end

    def update(src_path)
      data = prepare_for_aws(src_path)

      @client.update_function_code function_name: @name, zip_file: data
    end

    def delete
      @client.delete_function function_name: @name
    end

    private

    def prepare_for_aws(src_path)
      compiled_src = Compiler.new(src_path).run
      Packager.new(@name, compiled_src).package
    end

    def default_region
      `aws configure get region`.chomp
    end
  end
end
