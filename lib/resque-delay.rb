require 'resque'
require 'resque-scheduler'
require 'active_support/all'

require 'resque_delay/serialized_object'
require 'resque_delay/performable_method'
require 'resque_delay/delay_proxy'
require 'resque_delay/message_sending'

Object.send(:include, ResqueDelay::MessageSending)
