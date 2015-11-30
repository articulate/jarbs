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

      if @config.get('crashes.report', from_global: true)
        CrashReporter.configure do |c|
          c.engines = [CrashReporter::GithubIssues.new('articulate/jarbs', @config.get('github.token', from_global: true))]
          c.version = Jarbs::VERSION
        end
      end
    end

    def run
      program :version, Jarbs::VERSION
      program :description, 'Lambda Tooling'

      global_option('-e', '--env [dev]', String, 'Set deployment environment')
      global_option('-d', '--debug', 'Enable debug mode') { $debug = true }
      global_option('-p', '--profile PROFILE', String, 'AWS credential profile to use') do |profile|
        @config.set('aws.profile', profile)
      end

      command :config do |c|
        c.syntax = 'jarbs config [options]'
        c.option '-g', '--global', String, "Use global config"
        c.action do |args, options|
          method = args.shift

          if method == 'set'
            args.each do |settings|
              k, v = settings.split("=")

              @config.set(k, v, from_global: options.global)
            end
          elsif method == 'get'
            @config.get(args.first, from_global: options.global)
          elsif method == 'delete'
            @config.delete(args.first, from_global: options.global)
          else
            @config.print(for_global: options.global)
          end
        end
      end

      command :init do |c|
        c.syntax = 'jarbs init'
        c.summary = 'Setup lambda project in an existing directory'
        c.description = <<-DESC
Git ignores jarbs project definition file so on checkout of an existing lambda function.
When checking out a project from source control or transitioning a legacy lambda codebase to use
with jarbs, you'll need to run this command to setup the initial config and run additional checks
for compatability.
        DESC
        c.action do |args, options|
          skip_setup = File.exists? '.jarbs'
          abort('Lambda project already initialized.') if skip_setup

          unless Dir.exists? 'lambdas'
            say_warning("This doesn't look like a jarbs-enabled project directory (missing lambdas subdir).")
            skip_setup = !agree('Continue (y/n)? ')
          end

          Config.touch unless skip_setup
        end
      end

      command :new do |c|
        c.syntax = 'jarbs new [options] name'
        c.summary = "Generate a new lambda function or project skeleton"
        c.option "-f", "--force", "Force overwrite of existing function definition"
        c.action do |args, options|
          name = args.shift || abort("Must provide a lambda name")
          options.default global_defaults

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
        c.option '--role [STRING]', String, 'IAM role for Lambda execution'
        c.option '--dry', 'Dry run (do not interact with AWS)'
        c.action do |args, options|
          name = args.shift || abort('Name argument required')
          options.default global_defaults

          lambda = Lambda.new(name, options)
          abort("Lambda '#{name}' does not exist.") unless lambda.exists?

          lambda.prepare

          if options.dry
            say_warning('Dry run: Did not deploy to lambda.')
          else
            lambda.deploy
          end
        end
      end

      command :rm do |c|
        c.syntax = 'jarbs rm NAME [NAME...]'
        c.summary = "Delete a lambda function"
        c.action do |args, options|
          abort('Name argument required') if args.empty?
          options.default global_defaults

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

      command :invoke do |c|
        c.syntax = 'jarbs run NAME [payload]'
        c.summary = 'Invoke the lambda function and prints the cloudwatch logs.'
        c.option '--file FILE', 'JSON file to use as the payload (ignored if payload is specified in the command).'
        c.action do |args, options|
          name = args.shift || abort('Name argument required')
          payload = args.shift || ""

          if payload.nil? && File.exists?(options.file)
            payload = File.read(options.file)
          end

          options.default global_defaults

          lambda = Lambda.new(name, options)
          lambda.invoke(payload)
        end
      end

      run!
    end

    private

    def profile
      @config.get('aws.profile') || 'default'
    end

    def global_defaults
      GLOBAL_DEFAULTS.merge profile: profile
    end

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
          abort("Function #{lambda.function.name} exists. Use the -f flag to force overwrite.")
        end
      end
    end

    def jarbs_project?
      File.exists?('.jarbs')
    end
  end
end
