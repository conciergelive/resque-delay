# frozen_string_literal: true

module ResqueDelay
  class PerformableMethod
    attr_accessor :object, :method, :args, :queue, :run_in, :kwargs

    def self.create(object, method, args, queue, run_in, **kwargs)
      raise NoMethodError, "undefined method `#{method}' for #{object.inspect}" unless object.respond_to?(method, true)
      new(object, method, args, queue, run_in, **kwargs)
    end

    def initialize(object, method, args, queue, run_in, **kwargs)
      self.object = dump_to_string(object)
      self.args   = args.map { |a| dump_to_string(a) }
      self.method = method.to_sym
      self.queue = queue
      self.run_in = run_in
      self.kwargs = kwargs.transform_values { |val| dump_to_string(val) }
    end

    def display_name
      SerializedObject.display_name(object, method)
    end

    def perform
      # Capture the actual name of the class/method that got sent to Resque for
      # NewRelic reporting. If we don't do this, all transactions for Resque
      # report ResqueDelay::DelayProxy.
      if defined?(::NewRelic) && NewRelic::Agent.respond_to?(:set_transaction_name)
        NewRelic::Agent.set_transaction_name(display_name)
      end

      if kwargs.blank?
        load_from_string(object).send(method, *loaded_args)
      else
        load_from_string(object).send(method, *loaded_args, **loaded_kwargs)
      end
    rescue => e
      if defined?(ActiveRecord) && e.kind_of?(ActiveRecord::RecordNotFound)
        true
      else
        raise
      end
    end

    def loaded_args
      args.map { |a| load_from_string(a) }
    end

    def loaded_kwargs
      kwargs&.transform_values { |v| load_from_string(v) }&.transform_keys(&:to_sym)
    end

    private

    def dump_to_string(value)
      SerializedObject.serialize(value)
    end

    def load_from_string(value)
      SerializedObject.deserialize(value)
    end
  end
end
