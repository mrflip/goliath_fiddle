require 'goliath'

#
# Wait the amount of time given by the 'delay' parameter before responding.
#
# Uses streaming response with a callback -- a less-elegant way to implement
# this than shown in sleepy.rb, but a reasonable demonstration of streaming.
#
class SleepyCallback < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay', :max => 5.0, :default => 1.5, :as => Float}

  def response(env)
    start = Time.now.utc.to_f
    delay = env.params['delay']
    env.logger.debug "timer #{start} [#{delay}]: start of response"

    tt = EM.add_timer(delay) do
      env.logger.debug "timer #{start} [#{delay}]: timer fired"
      now = Time.now.utc.to_f
      ('{"started":%f,"delay":%f,"actual":%f,"now":%f}' % [start, delay, now - start, now])
    end
    env.logger.debug "timer #{start} [#{delay}]: after launching response"

    [200, {'X-Responder' => self.class.to_s, 'X-Sleepy-Delay' => delay.to_s }, tt.callback]
  end
end
