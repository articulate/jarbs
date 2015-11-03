module Jarbs
  class ProjectGenerator
    include ManifestHelpers

    def initialize(name)
      @name = name
    end

    def generate
      FileUtils.mkdir @name

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

      write_package(manifest, @name)
      NodeBuild.new(nil).npm_install(@name)
    end
  end
end
