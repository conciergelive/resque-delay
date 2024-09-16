module ResqueDelay
  module MessageSending
    def delay(options = {})
      DelayProxy.new(self, options)
    end
  end
end
