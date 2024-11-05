module ResqueDelay
  # This check will work for Rails 4.2 through 7. BasicObject was deprecated in
  # Rails 4.0 and removed in 4.1. The replacement is called ProxyObject and works
  # in 4.1 through 7. ActiveSupport added #version in 4.2 so we have to do some
  # awkward version checking here.
  proxy_superclass =
    if ActiveSupport.respond_to?(:version)
      require 'active_support/proxy_object'
      ActiveSupport::ProxyObject
    else
      if ActiveSupport::VERSION::MAJOR == 4 && ActiveSupport::VERSION::MINOR == 1
        require 'active_support/proxy_object'
        ActiveSupport::ProxyObject
      else
        require 'active_support/basic_object'
        ActiveSupport::BasicObject
      end
    end

  class DelayProxy < proxy_superclass
    if defined?(::NewRelic)
      extend ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

      def self.with_tracing(performable_method)
        begin
          perform_action_with_newrelic_trace(
            :name => nil,
            :class_name => performable_method.display_name,
            :category => 'OtherTransaction/ResqueJob') do

            ::NewRelic::Agent::Transaction.merge_untrusted_agent_attributes(
              performable_method.args,
              :'job.resque.args',
              ::NewRelic::Agent::AttributeFilter::DST_NONE)

            yield
          end
        ensure
          # Stopping the event loop before flushing the pipe.
          # The goal is to avoid conflict during write.
          ::NewRelic::Agent.agent.stop_event_loop
          ::NewRelic::Agent.agent.flush_pipe_data
        end
      end
    end

    def initialize(target, options)
      @target = target
      @options = options

      # If resque-retry has been loaded, we can add custom extensions to allow
      # automatically retrying jobs.
      @retryable = defined?(::Resque::Plugins::Retry)

      check_class = defined?(::Integer) ? ::Integer : ::Fixnum
      if !@options[:in].nil? && !@options[:in].kind_of?(check_class)
        raise ::ArgumentError.new("Delayed settings must be a #{check_class}! not a #{@options[:in].class.name}")
      end
    end

    def delay_proxy_class
      if @retryable && @options[:retry] == :once
        ::ResqueDelay::DelayProxyRetryOnce
      elsif @retryable && @options[:retry] == true
        ::ResqueDelay::DelayProxyRetryBackoff
      else
        ::ResqueDelay::DelayProxy
      end
    end

    def method_missing(method, *args, **kwargs)
      queue = @options[:to] || :default
      run_in = @options[:in] || 0
      performable_method = PerformableMethod.create(@target, method, args, queue, run_in, **kwargs)
      if delay?
        ::Resque.enqueue_in_with_queue(queue, delay, delay_proxy_class, performable_method)
      else
        ::Resque::Job.create(queue, delay_proxy_class, performable_method)
      end
      performable_method
    end

    # Called asynchronously by Resque
    def self.perform(args)
      pm = performable_from_resque_args(args)

      if defined?(::NewRelic)
        with_tracing pm do
          pm.perform
        end
      else
        pm.perform
      end
    end

    def self.performable_from_resque_args(args)
      if args.respond_to?(:[])
        if args.key? "kwargs"
          PerformableMethod.new(args["object"], args["method"], args["args"], args["queue"], args["run_in"], **args["kwargs"])
        else
          PerformableMethod.new(args["object"], args["method"], args["args"], args["queue"], args["run_in"])
        end
      else
        PerformableMethod.new(*args)
      end
    end

    private

    def delay?
      delay.to_i > 0
    end

    def delay
      @delay ||= @options[:in]
    end
  end

  if defined?(::Resque::Plugins::Retry)
    class DelayProxyRetryOnce < DelayProxy
      extend ::Resque::Plugins::Retry

      def self.retry_queue(...)
        :retries
      end
    end
  end

  if defined?(::Resque::Plugins::ExponentialBackoff)
    class DelayProxyRetryBackoff < DelayProxy
      extend ::Resque::Plugins::ExponentialBackoff

      # Override "exponential" with our own values. Sidekiq does up to 30 days
      # of retries but that seems a bit excessive. A max of 5 days of retry
      # delay gives plenty of time to resolve issues that crop up on a weekend.
      @backoff_strategy = [
        30, # 30 secs
        2 * 60, # 2 mins
        10 * 60, # 10 mins
        30 * 60, # 30 mins
        1 * 3600, # 1 hr
        2 * 3600, # 2 hrs
        8 * 3600, # 8 hrs
        24 * 3600, # 1 day
        2 * 24 * 3600, # 2 days
        5 * 24 * 3600, # 5 days
      ]
      @retry_delay_multiplicand_min = 0.7
      @retry_delay_multiplicand_max = 1.3

      def self.retry_queue(...)
        :retries
      end
    end
  end
end
