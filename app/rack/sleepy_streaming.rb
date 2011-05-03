#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'

require 'boot'
require 'goliath'
require 'rack/abstract_format'
require 'yajl/json_gem'

#
# Wait the amount of time given by the 'delay' parameter before responding (default 2.5, max 15.0).
#
# Uses streaming response with a callback -- a less-elegant way to implement
# this than shown in sleepy_simple.rb, but a reasonable demonstration of streaming.
#
#
# Handles multiple parallel requests:
#
#   $ ./app/rack/sleepy_streaming.rb -sv -p 9002 -e prod &
#   [64277:INFO] 2011-04-24 17:17:31 :: Starting server on 0.0.0.0:9002 in development mode. Watch out for stones.
#
#   $ ab -c100 -n100  'http://127.0.0.1:9002/?delay=3.0'
#         Connection Times (ms)
#                       min  mean[+/-sd] median   max
#         Connect:        1    2   0.9      2       5
#         Processing:  3011 3038  10.4   3029    3053
#         Waiting:       10   34  19.9     53      54
#         Total:       3016 3040   9.6   3033    3054
#
class SleepyStreaming < Goliath::API
  use Goliath::Rack::Params
  use Rack::AbstractFormat, 'application/json'
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay',         :default => 2.5, :max => 15.0, :min => 0.0, :as => Float}

  def response(env)
    env[:delay] = env.params['delay']

    # send the body delayed this much after the headers
    EM.add_timer(env[:delay]) do
      logline env, "sending result"
      env.stream_send( JSON.generate(timing_info(env)) )
      env.stream_close
      logline env, "closed stream"
    end

    logline env, "done setup"
    streaming_response( 200, { 'X-Sleepy-Delay' => env[:delay].to_s } )
  end

protected
  def timing_info(env)
    {
      :start  => env[:start_time].to_f,
      :delay  => env[:delay],
      :actual => (Time.now.to_f - env[:start_time].to_f)
    }
  end

  def logline env, *args
    env.logger.debug "timer #{env[:start_time]} [#{env[:delay]}]: #{args.join("\t")}"
  end
end
