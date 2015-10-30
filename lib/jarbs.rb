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

      global_option('-d', '--debug', 'Enable debug mode') { $debug = true }

      command :new do |c|
        c.syntax = 'jarbs new [options] name'
        c.summary = "Generate a new lambda function skeleton"
        c.option "-f", "--force", "Force overwrite of existing function definition"
        c.action do |args, options|
          name = args.shift || abort("Must provide a lambda name")

          if Dir.exists? name
            if options.force
              FileUtils.rm_r name
            else
              abort("Function exists. Use the -f flag to force overwrite.")
            end
          end

          Lambda.new(name).generate
        end
      end

      command :deploy do |c|
        c.syntax = 'jarbs deploy [options] [name: defaults to dir specified by --dir flag]'
        c.summary = 'Deploy a new lambda function'
        c.option "--dir STRING", String, "Path of code dir to package"
        c.option "--no-compile", "Don't run compile step"
        c.action do |args, options|
          src_dir = options.dir || abort("--dir is required")
          name = args.shift || File.basename(options.dir)

          lambda = Lambda.new(name)
          lambda.create(options.dir, compile: !options.no_compile)
        end
      end

      command :update do |c|
        c.syntax = 'jarbs update [options] [name: defaults to dir specified by --dir flag]'
        c.summary = 'Update an existing lambda function'
        c.option "--dir STRING", String, "Path of code dir to package"
        c.option "--no-compile", "Don't run compile step"
        c.action do |args, options|
          src_dir = options.dir || abort("--dir is required")
          name = args[0] || File.basename(options.dir)

          lambda = Lambda.new(name)
          lambda.update(options.dir, compile: !options.no_compile)
        end
      end

      command :rm do |c|
        c.syntax = 'jarbs rm NAME [NAME...]'
        c.summary = "Delete a lambda function"
        c.action do |args, options|
          begin
            args.each do |fn|
              begin
                Lambda.new(fn).delete
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
