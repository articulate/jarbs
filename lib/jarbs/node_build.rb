module Jarbs
  class NodeBuild
    include Commander::UI

    def initialize(function)
      @function = function
    end

    def npm_install
      say_ok "Installing npm dependencies..."
      run_in @function.root_path, 'npm install'
    end

    def npm_build
      say_ok "Building function..."
      npm_install

      # Copy source dir to build location and build in-place
      FileUtils.cp_r @function.source_path, @function.build_path
      run_in @function.root_path, 'npm run build'

      # Copy dependencies and manifest file
      FileUtils.cp_r File.join(@function.root_path, 'node_modules'), @function.build_path
      FileUtils.cp @function.manifest_file, @function.build_path

      # Clean deps for production-only
      run_in @function.build_path, 'npm prune --production'
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
