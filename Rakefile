require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "goliath_doodads"
  gem.homepage = "http://infochimps.com/labs"
  gem.license = "MIT"
  gem.summary = %Q{Experiments with the goliath (http://goliath.io) super-fast asynchronous ruby API framework}
  gem.description = %Q{Experiments with the goliath (http://goliath.io) super-fast asynchronous ruby API framework}
  gem.email = "coders@infochimps.org"
  gem.authors = ["Infochimps"]

  gem.add_runtime_dependency     'goliath', "~> 0.9.1"

  gem.add_development_dependency 'bundler', "~> 1.0.0"
  gem.add_development_dependency 'rspec',   "~> 2.3.0"
  gem.add_development_dependency 'yard',    "~> 0.6.0"
  gem.add_development_dependency 'jeweler', "~> 1.5.2"
  gem.add_development_dependency 'rcov',    ">= 0"
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
