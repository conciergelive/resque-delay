# Copied/adapted from NewRelic gem v7.0.0. We can't use the built-in Resque
# instrumentation because it reports every single delay proxied job as
# "DelayProxy#perform" which is not helpful.

::NewRelic::Agent.logger.info 'Installing Resque instrumentation'
if NewRelic::Agent.config[:'resque.use_ruby_dns'] && NewRelic::Agent.config[:dispatcher] == :resque
  ::NewRelic::Agent.logger.info 'Requiring resolv-replace'
  require 'resolv'
  require 'resolv-replace'
end

if ::NewRelic::LanguageSupport.can_fork?
  ::Resque.before_first_fork do
    ::NewRelic::Agent.manual_start(:dispatcher   => :resque,
                                   :sync_startup => true,
                                   :start_channel_listener => true)
  end

  ::Resque.before_fork do |job|
    if ENV['FORK_PER_JOB'] != 'false'
      ::NewRelic::Agent.register_report_channel(job.object_id)
    end
  end

  ::Resque.after_fork do |job|
    # Only suppress reporting Instance/Busy for forked children
    # Traced errors UI relies on having the parent process report that metric
    ::NewRelic::Agent.after_fork(:report_to_channel => job.object_id,
                                 :report_instance_busy => false)
  end
end
