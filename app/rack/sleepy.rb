#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'

require 'boot'
require 'goliath'
require 'yajl/json_gem'
require 'gorillib'
require 'gorillib/numeric/clamp'

#
# Response takes 'delay' seconds to complete (default 2.5, max 15.0).
# Waits for '_initial_delay' seconds (default 0) before sending headers.
#
# Handles multiple parallel requests:
#
#   $ ruby app/endpoints/sleepy_streaming.rb -sv -p 9002 &
#   [64277:INFO] 2011-04-24 17:17:31 :: Starting server on 0.0.0.0:9002 in development mode. Watch out for stones.
#
#   ab -c100 -n100  'http://127.0.0.1:9002/meta/http/sleep.json?_initial_delay=1.0&delay=3.0'
#
#         Connection Times (ms)
#                       min  mean[+/-sd] median   max
#         Connect:        2    4   0.8      4       5
#         Processing:  3006 3293 168.7   3309    3576
#         Waiting:     1006 1293 168.8   1309    1576
#         Total:       3011 3297 168.0   3313    3578
#
class Sleepy < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay',          :default => 2.5, :max => 15.0, :min => 0.0, :as => Float}
  use Goliath::Rack::Validation::NumericRange, {:key => '_initial_delay', :default => 0.0, :max => 10.0, :min => 0.0, :as => Float}

  def response(env)
    logline env, "params", env.params.inspect
    env[:initial_delay]  = env.params['_initial_delay']
    env[:response_delay] = (env.params['delay'] - env.params['_initial_delay']).clamp(0, 10.0)
    logline env, "beg"

    # sleep for a period
    EM::Synchrony.sleep(env[:initial_delay])
    logline env, "after sleep"

    # send the body delayed this much after the headers
    EM.add_timer(env[:response_delay]) do
      logline env, "sending body"
      env.chunked_stream_send(body(env))
      env.chunked_stream_close
      logline env, "closed stream"
    end

    logline env, "after setup"
    return chunked_streaming_response(200, {'X-Responder' => self.class.to_s,
      'X-Sleepy-Initial-Delay' => env[:initial_delay].to_s, 'X-Sleepy-Response-Delay' => env[:response_delay].to_s, })
  end

protected

  def logline env, *args
    env.logger.debug [self.class, env[:start_time], env[:initial_delay], env[:response_delay], Time.now.to_f - env[:start_time], *args].flatten.join("\t")
  end

  def body(env)
    JSON.generate({
        :start            => env[:start_time].to_f,
        :response_delay   => env[:response_delay],
        :initial_delay    => env[:initial_delay],
        :actual           => (Time.now.to_f - env[:start_time].to_f) }
      )
  end
end
