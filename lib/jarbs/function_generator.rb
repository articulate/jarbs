module Jarbs
  class FunctionGenerator
    include Commander::UI
    include ManifestHelpers

    def initialize(function)
      @function = function
    end

    def generate
      say_ok "Generating function skeleton at #{@function.root_path}"

      FileUtils.mkdir_p @function.source_path
      install_manifest
      install_handler
    end

    private

    def install_manifest
      package_manifest = {
          name: @function.name,
          version: '0.0.0',
          description: ask('Function description: '),
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
          dependencies: {
              'babel-runtime' => '< 6'
          }
      }

      write_package(package_manifest, @function.source_path)
    end

    def install_handler
      install_fixture('index.js', @function.source_path)
    end
  end
end
