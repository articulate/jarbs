require 'rubygems'
require 'fileutils'
require 'commander'

require_relative 'jarbs/lambda'

module Jarbs
  class CLI
    include Commander::Methods

    def run
      program :version, '0.0.1'
      program :description, 'Lambda Tooling'

      global_option('-d', '--debug', 'Enable debug mode') { $debug = true }

      command :new do |c|
        c.syntax = 'jarbs new [options] [name: defaults to dir specified by --dir flag]'
        c.summary = 'Create new lambda function'
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
        c.summary = 'Update a lambda function'
        c.option "--dir STRING", String, "Path of code dir to package"
        c.option "--no-compile", "Don't run compile step"
        c.action do |args, options|
          name = args[0] || File.basename(options.dir)

          lambda = Lambda.new(name)
          lambda.update(options.dir, compile: !options.no_compile)
        end
      end

      command :rm do |c|
        c.syntax = 'jarbs rm NAME'
        c.summary = "Delete a lambda function"
        c.action do |args, options|
          lambda = Lambda.new(args[0])
          lambda.delete
        end
      end

      command :logs do |c|
        c.syntax = 'jarbs logs [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--some-switch', 'Some switch that does something'
        c.action do |args, options|
          # Do something or c.when_called Jarbs::Commands::Logs
        end
      end

      command :run do |c|
        c.syntax = 'jarbs run [options]'
        c.summary = ''
        c.description = ''
        c.example 'description', 'command example'
        c.option '--some-switch', 'Some switch that does something'
        c.action do |args, options|
          # Do something or c.when_called Jarbs::Commands::Run
        end
      end

      run!
    end
  end
end
