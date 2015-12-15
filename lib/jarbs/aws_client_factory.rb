module Jarbs
  class AwsClientFactory
    def initialize(options)
      @credentials = Aws::SharedCredentials.new(profile_name: options.profile)
    end

    # @return [Aws::Lambda::Client]
    def lambda_client
      @lambda ||= Aws::Lambda::Client.new client_options
    end

    # @return [Aws::CloudWatchLogs::Client]
    def log_client
      @logs ||= Aws::CloudWatchLogs::Client.new client_options
    end

    def iam_client
      @iam ||= Aws::IAM::Client.new client_options
    end

    private

    def client_options
      { region: default_region, credentials: @credentials }
    end

    def default_region
      `aws configure get region`.chomp
    end
  end
end
