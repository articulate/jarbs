module Jarbs
  class ProjectGenerator
    include ManifestHelpers
    def initialize(name)
      @name = name
    end

    def generate
      manifest = {
          name: @name,
          version: '0.0.0',
          author: whoami,
          repository: {
              type: 'git',
              url: repo_url
          },
          license: 'UNLICENSED',
          engines: {
              node: '0.10.36'
          },
          main: 'index.js',
          scripts: {
              'build:function' => 'babel --optional runtime',
          },
          devDependencies: {
              'babel' => '< 6',
              'babel-runtime' => '< 6'
          }
      }

      FileUtils.mkdir @name

      Dir.chdir(@name)

      write_package(manifest, '.')
      install_gitignore

      NodeBuild.new(nil).npm_install('.')

      setup_crash_logging
    end

    private

    def install_gitignore
      install_fixture('.gitignore', '.')
    end

    def setup_crash_logging
      config = Config.global
      autolog = config.get('crashes.report') do
        agree("Would you like to log jarbs crashes to GitHub automatically (y/n)? ")
      end

      if autolog and !config.exists?('github.token')
        GithubAuth.new(config).generate_token(@name)
      end
    end
  end
end
