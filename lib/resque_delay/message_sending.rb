require 'active_support/proxy_object'

module ResqueDelay
  class DelayProxy < ActiveSupport::ProxyObject
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
      if !@options[:in].nil? && !@options[:in].kind_of?(::Fixnum)
        raise ::ArgumentError.new("Delayed settings must be a Fixnum! not a #{@options[:in].class.name}") 
      end
    end

    def method_missing(method, *args)
      queue = @options[:to] || :default
      run_in = @options[:in] || 0
      performable_method = PerformableMethod.create(@target, method, args, queue, run_in)
      ::Resque::Job.new(queue, performable_method)
      if delay?
        ::Resque.enqueue_in_with_queue(queue, delay, DelayProxy, performable_method)
      else
        ::Resque::Job.create(queue, DelayProxy, performable_method)
      end
      performable_method
    end

    # Called asynchronously by Resque
    def self.perform(args)
      pm =
        if args.respond_to?(:[])
          PerformableMethod.new(args["object"], args["method"], args["args"], args["queue"], args["run_in"])
        else
          PerformableMethod.new(*args)
        end

      if defined?(::NewRelic)
        with_tracing pm do
          pm.perform
        end
      else
        pm.perform
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

  module MessageSending
    def delay(options = {})
      DelayProxy.new(self, options)
    end
  end
end
