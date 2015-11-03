require 'rugged'

module Jarbs
  class SkeletonGenerator
    include Commander::UI

    def initialize(function)
      @function = function
    end

    def create_project
      say_ok "Generating function skeleton at #{@function.source_path}"
      FileUtils.mkdir_p @function.source_path

      build_manifest
      install_handler
    end

    def build_manifest
      package_manifest = {
          name: @function.name,
          version: '0.0.0',
          description: ask("Function description: "),
          author: `whoami`.chomp,
          repository: {
              type: "git",
              url: repo_url
          },
          license: "UNLICENSED",
          engines: {
              node: "0.10.36"
          },
          main: "index.js",
          scripts: {
              build: "babel --optional runtime --out-dir dest src",
          },
          dependencies: {
              'babel-runtime' => '< 6'
          },
          devDependencies: {
              'babel' => '< 6'
          }
      }

      # generate manifest file
      File.open(File.join(@function.root_path, 'package.json'), 'w') do |f|
        f.write JSON.pretty_generate(package_manifest)
      end
    end

    def install_handler
      FileUtils.cp File.join(File.dirname(__FILE__), 'fixtures', 'index.js'), @function.source_path
    end

    private

    def repo_url
      Rugged::Repository.discover(".").remotes.first.url
    rescue Rugged::RepositoryError => e
      nil
    end
  end
end
