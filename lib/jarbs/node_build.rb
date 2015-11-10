module Jarbs
  class NodeBuild
    include Commander::UI
    include CrashReporter::DSL

    MIN_NPM_VERSION = 2

    def initialize(function)
      @function = function
      check_npm_version
    end

    def npm_install(path, flags="")
      capture_errors { run_in(path, "npm install #{flags}") }
    end

    def npm_build
      say_ok 'Building function...'

      # Copy source dir to build location and build in-place
      FileUtils.cp_r @function.source_path, @function.build_path

      capture_errors do
        abortable_run "npm run build:function -- --out-dir #{@function.build_path} #{@function.source_path}"

        npm_install @function.build_path, '--production'
      end
    end

    def clean
      FileUtils.rm_r @function.build_path if Dir.exists?(@function.build_path)
    end

    private

    def run_in(location, cmd)
      Dir.chdir(location) { abortable_run(cmd) }
    end

    def abortable_run(cmd)
      success = system(cmd)
      abort("cpm runtime exited with non-zero status code: #{$?.exitstatus}") unless success
    end

    def check_npm_version
      unless npm_version_major >= MIN_NPM_VERSION
        say_warning "NPM should be at #{MIN_NPM_VERSION}.x or greater (currently #{npm_version})"
      end
    end

    def npm_version
      @npm_version ||= `npm -v`.chomp
    end

    def npm_version_major
      npm_version.split('.').first.to_i
    end
  end
end
