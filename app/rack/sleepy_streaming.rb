require 'goliath'
require 'yajl/json_gem'

#
# Wait the amount of time given by the 'delay' parameter before responding.
#
# Uses streaming response with a callback -- a less-elegant way to implement
# this than shown in sleepy.rb, but a reasonable demonstration of streaming.
#
class SleepyStreaming < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay', :max => 5.0, :default => 1.5, :as => Float}

  def response(env)
    start = Time.now.utc.to_f
    delay = env.params['delay']
    env.logger.debug "timer #{start} [#{delay}]: start of response"

    # Need to do this at next tick, so that the stream exists
    EM.next_tick do
      body = { :start => start, :delay => delay, :stream_opened => Time.now.utc.to_f }
      env.stream_send( body.to_json + "\n" )
    end

    tt = EM.add_timer(delay) do
      env.logger.debug "timer #{start} [#{delay}]: timer fired; sending rest of body"

      now  = Time.now.utc.to_f
      body = { :start => start, :delay => delay, :stream_closed => now, :actual => (now - start) }
      env.stream_send( body.to_json + "\n" )
      env.stream_close
      env.logger.debug "timer #{start} [#{delay}]: stream closed"
    end

    env.logger.debug "timer #{start} [#{delay}]: after launching response"
    [202, {'X-Responder' => self.class.to_s, 'X-Sleepy-Delay' => delay.to_s, 'X-Stream' => 'Goliath', }, Goliath::Response::STREAMING]
  end
end
