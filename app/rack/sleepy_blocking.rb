require 'goliath'

#
# Wait the amount of time given by the 'delay' parameter before responding.
# Cannot handle multiple parallel requests -- its sleep call blocks the reactor, the WRONG thing for a goliath endpoint
#
class SleepyBlocking < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format
  use Goliath::Rack::ValidationError    # catch and render validation errors
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay', :max => 5.0, :default => 1.5, :as => Float}

  def response(env)
    start = Time.now.utc.to_f
    delay = env.params['delay']
    env.logger.debug "timer #{start} [#{delay}]: start of response"

    # This call call **blocks the reactor**, the **WRONG** thing for a goliath endpoint
    sleep delay
    body = { :start => start, :delay => delay, :actual => (Time.now.utc.to_f - start) }

    env.logger.debug "timer #{start} [#{delay}]: after sleep: #{body.inspect}"
    [200, {'X-Responder' => self.class.to_s, 'X-Sleepy-Delay' => delay.to_s, }, body]
  end
end
