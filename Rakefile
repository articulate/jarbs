require "bundler/gem_tasks"
require 'jarbs/version'
# require "rake/testtask"

# Rake::TestTask.new(:test) do |t|
#   t.libs << "test"
#   t.libs << "lib"
#   t.test_files = FileList['test/**/*_test.rb']
# end

# task :default => :test

namespace :articulate do
  task :release do
    version = Jarbs::VERSION

    system "bundle install"
    system "git commit -am 'bump version for #{version} release"
    system "gem_push=no rake release"
    system "gem push ./pkg/jarbs-#{version}.gem --host https://artifactory.articulate.com/artifactory/api/gems/rubygems-local"
  end
end
