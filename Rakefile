require "bundler/gem_tasks"
require 'jarbs/version'
# require "rake/testtask"

# Rake::TestTask.new(:test) do |t|
#   t.libs << "test"
#   t.libs << "lib"
#   t.test_files = FileList['test/**/*_test.rb']
# end

# task :default => :test

def abortable_run(cmd)
  abort("Failed with #{$?.exitstatus}") unless system(cmd)
end

namespace :articulate do
  task :release do
    version = Jarbs::VERSION

    abortable_run "bundle install"
    abortable_run "git commit -am 'bump version for #{version} release'"
    abortable_run "gem_push=no rake release"
    abortable_run "gem push ./pkg/jarbs-#{version}.gem --host https://artifactory.articulate.com/artifactory/api/gems/rubygems-local"
  end
end
