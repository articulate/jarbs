require 'rugged'

module Jarbs
  module ManifestHelpers

    def write_package(manifest, path)
      File.open(File.join(path, 'package.json'), 'w') do |f|
        f.write JSON.pretty_generate(manifest)
      end
    end

    def whoami
      @whoami ||= `whoami`.chomp
    end

    def repo_url
      Rugged::Repository.discover(".").remotes.first.url
    rescue Rugged::RepositoryError => e
      nil
    end
  end
end
