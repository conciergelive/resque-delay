Gem::Specification.new do |s|
  s.name              = "resque-delay"
  s.version           = "0.6.0"
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Enable send_later/delay for Resque"
  s.homepage          = "http://github.com/rykov/resque-delay"
  s.email             = "mrykov@gmail"
  s.authors           = [ "Michael Rykov" ]

  s.files             = %w( README.md Rakefile LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("test/**/*")
  s.files            += Dir.glob("spec/**/*")

  s.add_dependency    "resque", ">= 1.25"
  s.add_dependency    "resque-scheduler", ">= 4.0.0"
  s.add_dependency    "activesupport", "< 6"

  s.add_development_dependency "coveralls"
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-nc'
  s.add_development_dependency 'rspec-mocks'
  s.add_development_dependency 'resque'
  s.add_development_dependency 'resque-scheduler'
  s.add_development_dependency 'activerecord', '~> 5.2'
  s.add_development_dependency 'activesupport', '~> 5.2'
  s.add_development_dependency 'data_mapper'
  s.add_development_dependency 'mongoid'
  s.add_development_dependency 'pry'

  s.description = <<DESCRIPTION
Enable send_later support for Resque
DESCRIPTION
end
