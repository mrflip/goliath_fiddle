require 'logger'
require 'goliath'
require 'yajl/json_gem'

#
# This responder will wait a given amount of time before responding, but cannot
# handle multiple parallel requests.
#
class SleepyBlocking < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use ::Rack::Reloader, 0 if Goliath.dev?

  # longest allowable delay
  MAX_DELAY    = 5.0

  def response(env)
    p env
    start = Time.now.utc.to_f

    delay = (env.params['delay'] || 1.0).to_f
    delay = MAX_DELAY if delay > MAX_DELAY
    env.logger.debug "timer #{start} [#{delay}]: before"
    sleep delay

    now = Time.now.utc.to_f ; actual = now - start
    body = { :started => start, :delayed => delay, :actual => actual, :now => now }.to_json

    env.logger.debug "timer #{start} [#{delay}]: after (#{body})"
    [200, {'X-Goliath-Responder' => self.class.to_s, 'X-Sleepy-Delay' => delay.to_s, 'X-Z' => '1' }, body]
  end
end
