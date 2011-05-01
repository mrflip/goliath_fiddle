require File.expand_path(File.dirname(__FILE__)+'/../../lib/boot')
require 'goliath'
require 'goliath/simple_frontend'
require 'goliath/rack/static_files'
require 'goliath/rack/validation_error_as_json'
require 'goliath/validation/standard_http_errors'
require 'rack/abstract_format'
require 'yajl/json_gem'

require 'goliath/rack/formatters/yaml'

#
require 'gorillib'
require 'gorillib/string/inflections'
require 'gorillib/string/constantize'

ENDPOINTS = {
  '/hello'                      => { :handler => 'hello_world',      :description => "A hello_world endpoint" },
  '/meta/http/sleepy'           => { :handler => 'sleepy',           :description => "A sleepy endpoint" },
  '/meta/http/sleepy_blocking'  => { :handler => 'sleepy_blocking',  :description => "A sleepy_blocking endpoint" },
  '/meta/http/sleepy_callback'  => { :handler => 'sleepy_callback',  :description => "A sleepy_callback endpoint" },
  '/meta/http/sleepy_streaming' => { :handler => 'sleepy_streaming', :description => "A sleepy_streaming endpoint" },
  '/meta/http/sleepy_streaming' => { :handler => 'every',            :description => "A sleepy_streaming endpoint" },
  '/meta/http/multi'            => { :handler => 'multi',            :description => "A multi endpoint" },
}

ENDPOINTS.each do |route, info|
  require Goliath.root_path('app/rack', info[:handler])
end


class RootView < Goliath::SimpleFrontend
  def response(env)
    path    = env['PATH_INFO'].gsub(%r{(.+)/$}, '\1')
    headers = {'X-Responder' => self.class.to_s, 'Content-Type' => 'text/html' }
    body = haml :root, :endpoints => ENDPOINTS
    [200, headers, body]
  end
end

#
# Renders a templated view
#
class ViewRoutes < Goliath::API
  use Goliath::Rack::Params                           # parse query & body params
  use Goliath::Rack::StaticFiles, :cache_age => 36000 # serve static files from /public
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Formatters::XML    # JSON output formatter
  use Goliath::Rack::Formatters::YAML    # JSON output formatter
  use Goliath::Rack::Render                           # auto-negotiate response format
  use Rack::AbstractFormat
  # use Goliath::Rack::ValidationErrorAsJson            # catch errors and respond with appropriate response code.

  use Goliath::Rack::Validation::NumericRange, {:key => 'delay', :max => 5.0, :default => 1.5, :as => Float}

  map '/' do
    run RootView.new
  end

  ENDPOINTS.each do |route, info|
    handler_klass = info[:handler].camelize.constantize
    map route do
      run handler_klass.new
    end
  end
end
