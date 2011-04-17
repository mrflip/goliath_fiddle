require 'goliath'

$: << File.expand_path(File.dirname(__FILE__)+'/../../lib')
require 'goliath/rack/force_status'

#
# Aggregates utility middlewares (force_status, echo_params, delay, ...)
# into a useful testing endpoint
#
class ResponseUtil < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format
  use Goliath::Rack::ValidationError    # catch and render validation errors
  #
  use Goliath::Rack::ForceStatus        # util: let requestor set status code
  # use Goliath::Rack::EchoParams       # util: echo params back into result hash
  # use Goliath::Rack::Delay            # util: make request take (at least) given length of time

  def response(env)
    start = Time.now.utc.to_f
    env.logger.debug "#{self.class} #{start}: start of response"

    result = { :result => "Hello, World", :now => start }
    [200, {'X-Responder' => self.class.to_s }, result]
  end
end

