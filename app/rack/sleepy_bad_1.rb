require 'logger'
require 'goliath'

#
# This responder will wait a given amount of time before responding -- yet can
# handle multiple parallel requests.
#
# This is a demonstration of WRONG THING NUMBER ONE: streaming response order
#
class SleepyBad1 < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format
  use Goliath::Rack::ValidationError    # catch and render validation errors
  use ::Rack::Reloader, 0 if Goliath.dev?

  # longest allowable delay
  MAX_DELAY    = 5.0

  def response(env)
    start = Time.now.utc.to_f

    delay = (env.params['delay'] || 1.0).to_f
    delay = MAX_DELAY if delay > MAX_DELAY
    env.logger.debug "timer #{start} [#{delay}]: before"

    #
    # THE WRONG THING: this will send before the headers!
    #
    env.stream_send('{"started":%f,"stream_started":%f' % [start, Time.now.utc.to_f])

    EM.add_timer(delay) do
      env.logger.debug "timer #{start} [#{delay}]: timer fired"

      now = Time.now.utc.to_f ; actual = now - start
      env.stream_send(',"delay":%f,"actual":%f,"now":%f}' % [delay, actual, now])
      env.stream_close
      env.logger.debug "timer #{start} [#{delay}]: connection closed"
    end
    env.logger.debug "timer #{start} [#{delay}]: after"
    [200, {'X-Goliath-Responder' => self.class.to_s, 'X-Sleepy-Delay' => delay.to_s }, Goliath::Response::STREAMING]
  end
end
