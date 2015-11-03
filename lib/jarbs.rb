require 'rubygems'
require 'fileutils'
require 'commander'

require 'jarbs/version'
require 'jarbs/lambda'

module Jarbs
  class CLI
    include Commander::Methods

    def run
      program :version, Jarbs::VERSION
      program :description, 'Lambda Tooling'

      global_option('-e', '--env ENV', String, 'Set deployment environment [Default to "dev"]')
      global_option('-d', '--debug', 'Enable debug mode') { $debug = true }

      command :new do |c|
        c.syntax = 'jarbs new [options] name'
        c.summary = "Generate a new lambda function skeleton"
        c.option "-f", "--force", "Force overwrite of existing function definition"
        c.action do |args, options|
          options.default env: 'dev'

          name = args.shift || abort("Must provide a lambda name")

          if Dir.exists? name
            if options.force
              FileUtils.rm_r name
            else
              abort("Function exists. Use the -f flag to force overwrite.")
            end
          end

          Lambda.new(name, options).generate
        end
      end

      command :deploy do |c|
        c.syntax = 'jarbs deploy [options] directory'
        c.summary = 'Deploy a new lambda function'
        c.option "--dir STRING", String, "Path of code dir to package"
        c.option "--role STRING", String, "IAM role for Lambda execution"
        c.action do |args, options|
          name = args.shift || abort('Name argument required')

          options.default env: 'dev',
                          dir: name

          Lambda.new(name, options).create
        end
      end

      command :update do |c|
        c.syntax = 'jarbs update [options] name'
        c.summary = 'Update an existing lambda function'
        c.option "--dir STRING", String, "Path of code dir to package"
        c.action do |args, options|
          name = args.shift || abort('Name argument required')

          options.default env: 'dev',
                          dir: name

          Lambda.new(name, options).update
        end
      end

      command :rm do |c|
        c.syntax = 'jarbs rm NAME [NAME...]'
        c.summary = "Delete a lambda function"
        c.action do |args, options|
          name = args.shift || abort('Name argument required')

          options.default env: 'dev',
                          dir: name

          begin
            args.each do |fn|
              begin
                Lambda.new(fn, options).delete
              rescue Aws::Lambda::Errors::ResourceNotFoundException => e
                say_error "Function \"#{fn}\" does not exists. Ignoring."
                next
              end
            end
          end
        end
      end

      run!
    end
  end
end
