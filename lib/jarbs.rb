require 'rubygems'
require 'fileutils'
require 'commander'

require 'crash_reporter'
require 'crash_reporter/reporters/github_issues'

require 'jarbs/version'
require 'jarbs/config'
require 'jarbs/github_auth'
require 'jarbs/lambda'

module Jarbs
  class CLI
    include Commander::Methods

    GLOBAL_DEFAULTS = { env: 'dev' }

    def initialize
      @config = Config.new

      if @config.get('crashes.report')
        CrashReporter.configure do |c|
          c.engines = [CrashReporter::GithubIssues.new('articulate/jarbs', @config.get('github.token'))]
          c.version = Jarbs::VERSION
        end
      end
    end

    def run
      program :version, Jarbs::VERSION
      program :description, 'Lambda Tooling'

      global_option('-e', '--env ENV', String, 'Set deployment environment [Default to dev]')
      global_option('-d', '--debug', 'Enable debug mode') { $debug = true }

      command :new do |c|
        c.syntax = 'jarbs new [options] name'
        c.summary = "Generate a new lambda function or project skeleton"
        c.option "-f", "--force", "Force overwrite of existing function definition"
        c.action do |args, options|
          name = args.shift || abort("Must provide a lambda name")
          options.default GLOBAL_DEFAULTS

          lambda = Lambda.new(name, options)

          project_exists?(name, remove: options.force)
          lambda_exists?(lambda, remove: options.force)

          ProjectGenerator.new(name).generate unless jarbs_project?
          lambda.generate
        end
      end

      command :deploy do |c|
        c.syntax = 'jarbs deploy [options] directory'
        c.summary = 'Deploy a lambda function to AWS'
        c.option "--role [STRING]", String, "IAM role for Lambda execution"
        c.action do |args, options|
          name = args.shift || abort('Name argument required')
          options.default GLOBAL_DEFAULTS

          lambda = Lambda.new(name, options)

          abort("Lambda '#{name}' does not exist.") unless lambda.exists?

          lambda.deploy
        end
      end

      command :rm do |c|
        c.syntax = 'jarbs rm NAME [NAME...]'
        c.summary = "Delete a lambda function"
        c.action do |args, options|
          abort('Name argument required') if args.empty?
          options.default GLOBAL_DEFAULTS

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

      command :ls do |c|
        c.syntax = 'jarbs ls'
        c.summary = "List lambda functions in this project"
        c.action do |args, options|
          lambdas = Dir.glob("lambdas/*").map {|x| Lambda.new(File.basename(x), options) }

          lambdas.each do |l|
            say "#{l.function.name}: #{l.function.description}"
          end
        end
      end

      run!
    end

    private

    def project_exists?(name, remove: false)
      if Dir.exists? name
        if remove
          FileUtils.rm_r name
        else
          abort("Project #{name} exists. Use the -f flag to force overwrite.")
        end
      end
    end

    def lambda_exists?(lambda, remove: false)
      if lambda.function.exists?
        if remove
          lambda.function.remove!
        else
          abort("Function #{lambda.name} exists. Use the -f flag to force overwrite.")
        end
      end
    end

    def jarbs_project?
      File.exists?('.jarbs')
    end

  end
end
