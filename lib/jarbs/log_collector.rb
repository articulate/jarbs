module Jarbs
  class LogCollector
    include Commander::UI
    include CrashReporter::DSL

    LAMBDA_PATTERN = '[timestamp=*Z, request_id="*-*", event]'

    def initialize(function, options)
      @function = function
      @factory = AwsClientFactory.new(options)
    end

    def add_permissions(logger_function)
      @factory.lambda_client.add_permission function_name: logger_function,
        statement_id: permissions_id,
        principal: "logs.us-east-1.amazonaws.com",
        action: "lambda:InvokeFunction",
        source_arn: log_arn,
        source_account: account_id

      say_ok "Added permissions for CloudWatch logging"
    rescue Aws::Lambda::Errors::ResourceConflictException => e
      say_warning "Attempted to add permissions for CloudWatch, but already exists."
    end

    def remove_permissions(logger_function)
      @factory.lambda_client.remove_permission statement_id: permissions_id,
        function_name: logger_function

      say_ok "Revoked permissions for CloudWatch logging"
    end

    def create_group
      @factory.log_client.create_log_group log_group_name: @function.log_group_name
      say_ok "Created new log group #{@function.log_group_name}"
    rescue Aws::CloudWatchLogs::Errors::ResourceAlreadyExistsException => e
      say_warning "Attempted to create log group #{@function.log_group_name}, but already exists."
    end

    def enable(logger_function)
      capture_errors do
        create_group    # ensure the logging group exists
        add_permissions(logger_function) # ensure cloudwatch can invoke the function

        @factory.log_client.put_subscription_filter log_group_name: @function.log_group_name,
                                        filter_name: subscription_name,
                                        filter_pattern: LAMBDA_PATTERN,
                                        destination_arn: function_arn(logger_function)
      end

      say_ok "Logging enabled for #{@function.env_name}."
    end

    def disable(logger_function)
      capture_errors do
        @factory.log_client.delete_subscription_filter log_group_name: @function.log_group_name,
          filter_name: subscription_name

        remove_permissions(logger_function)

        say_ok "Logging disabled for #{@function.env_name}."
      end
    end

    private

    def account_id
      user = @factory.iam_client.get_user
      user.user.arn.match('^arn:aws:iam::([0-9]{12}):.*$')[1]
    end

    def function_arn(function_name)
      defn = @factory.lambda_client.get_function function_name: function_name
      defn.configuration.function_arn
    end

    def log_arn
      logs = @factory.log_client.describe_log_groups log_group_name_prefix: @function.log_group_name,
        limit: 1

      logs.log_groups.first.arn
    end

    def subscription_name
      "es-logging-#{@function.env_name}"
    end

    def permissions_id
      "#{subscription_name}-permissions"
    end
  end
end
