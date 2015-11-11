require 'octokit'

module Jarbs
  class GithubAuth
    include Commander::UI

    def initialize(config)
      @config = config
      @client = Octokit::Client.new \
        login: @config.get('github.username') { ask('GitHub username: ') },
        password: password('Password (not saved): ')
    end

    def generate_token(name)
      resp = @client.create_authorization scopes: ['public_repo'],
                                          note: "Jarbs error reporting for #{name}",
                                          headers: { 'X-GitHub-OTP' => ask('GitHub two-factor token: ') }

      @config.set('github.token', resp.token)
    end
  end
end
