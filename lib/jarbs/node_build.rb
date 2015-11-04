module Jarbs
  class NodeBuild
    include Commander::UI

    def initialize(function)
      @function = function
    end

    def npm_install(path, flags="")
      run_in path, "npm install #{flags}"
    end

    def npm_build
      say_ok 'Building function...'

      # Copy source dir to build location and build in-place
      FileUtils.cp_r @function.source_path, @function.build_path
      abortable_run "npm run build:function -- --out-dir #{@function.build_path} #{@function.source_path}"

      npm_install @function.build_path, '--production'
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
  end
end
