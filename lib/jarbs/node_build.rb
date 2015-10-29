module Jarbs
  class NodeBuild
    include Commander::UI

    def initialize(function)
      @function = function
    end

    def npm_install
      say_ok "Installing node deps in #{@function.source_path}..."
      Dir.chdir(@function.source_path) do
        system 'npm install --only=prod'
        system 'npm prune --production'
      end
    end
  end
end
