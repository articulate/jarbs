module Jarbs
  module ManifestHelpers

    def install_fixture(fixture_name, path)
      FileUtils.cp File.join(File.dirname(__FILE__), 'fixtures', fixture_name), path
    end

    def write_package(manifest, path)
      File.open(File.join(path, 'package.json'), 'w') do |f|
        f.write JSON.pretty_generate(manifest)
      end
    end

    def whoami
      @whoami ||= `whoami`.chomp
    end

    def repo_url
      @repo_url ||= `git config --get remote.origin.url`.chomp
    end
  end
end
