# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'kibana_url'
  s.version     = '1.0.1'
  s.date        = '2017-04-20'
  s.summary     = 'Builds Kibana query URLs.'
  s.description = 'Builds complex ULRs for Kibana with all settings prefilled.'
  s.authors     = ['coinbase']
  s.email       = 'julian.borrey@coinbase.com'
  s.homepage    = 'https://github.com/coinbase/kibana_url'
  s.license     = 'Apache-2.0'

  s.files = ['lib/kibana_url.rb']

  s.add_dependency 'contracts', '~> 0.14'
  s.add_development_dependency 'bundler', '~> 1.14'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rubocop', '~> 0.41'
  s.add_development_dependency 'timecop', '~> 0.7'
end
