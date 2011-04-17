require 'logger'
require 'goliath'
require 'yajl/json_gem'

require 'em-synchrony/em-http'

$: << File.expand_path(File.dirname(__FILE__)+'/../../lib')
require 'goliath/rack/force_response_code'

#
# Aggregates utility middlewares (force_response_code, echo_params, delay, ...)
# into a useful testing endpoint
#
class ResponseUtil < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format
  use Goliath::Rack::ValidationError    # catch and render validation errors
  #
  use Goliath::Rack::ForceResponseCode  # util: let requestor set response code
  # use Goliath::Rack::EchoParams       # util: echo params back into result hash
  # use Goliath::Rack::Delay            # util: make request take (at least) given length of time
  #
  use ::Rack::Reloader, 0 if Goliath.dev?

  def response(env)
    start = Time.now.utc.to_f
    env.logger.debug "#{self.class} #{start}: start of response"

    result = { :result => "Hello, World", :now => start }
    [200, {'X-Goliath-Responder' => self.class.to_s }, result]
  end
end
