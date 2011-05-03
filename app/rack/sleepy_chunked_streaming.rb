#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'

require 'boot'
require 'goliath'
require 'rack/abstract_format'
require 'yajl/json_gem'
require 'gorillib/numeric/clamp'

#
# Wait the amount of time given by the 'delay' parameter before responding (default 2.5, max 15.0).
# Waits for 'initial_delay' seconds (default 0) before sending headers.
#
# Uses HTTP 1.1 Chunked-Transfer Streaming, so headers and first part of
# response can be sent early
#
# Handles multiple parallel requests:
#
#   $ ./app/rack/sleepy_chunked_streaming.rb -sv -p 9002 -e prod
#   [64277:INFO] 2011-04-24 17:17:31 :: Starting server on 0.0.0.0:9002 in production mode. Watch out for stones.
#
#   $ ab -c100 -n100  'http://127.0.0.1:9002/?delay=3.0&initial_delay=1.0'
# 
#         Connection Times (ms)
#                       min  mean[+/-sd] median   max
#         Connect:        1    2   0.8      2       4
#         Processing:  3004 3038  25.9   3026    3070
#         Waiting:     1005 1039  25.8   1026    1070
#         Total:       3008 3041  25.2   3028    3071
#
class SleepyChunkedStreaming < Goliath::API
  use Goliath::Rack::Params
  use Rack::AbstractFormat, 'application/json'
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay',         :default => 2.5, :max => 15.0, :min => 0.0, :as => Float}
  use Goliath::Rack::Validation::NumericRange, {:key => 'initial_delay', :default => 0.0, :max => 10.0, :min => 0.0, :as => Float}

  def response(env)
    env[:delay]         = env.params['delay']
    env[:initial_delay] = env.params['initial_delay']
    env[:delay]         = env[:initial_delay] if (env[:delay] < env[:initial_delay])

    # EM::Synchrony call allows the reactor to keep spinning: HOORAY CONCURRENCY
    logline env, "sleeping"
    EM::Synchrony.sleep(env[:initial_delay])
    logline env, "after sleep"

    # send the body delayed this much after the headers
    EM.add_timer(env[:delay] - env[:initial_delay]) do
      logline env, "sending result"
      env.chunked_stream_send( JSON.generate(timing_info(env)) )
      env.chunked_stream_close
      logline env, "closed stream"
    end

    logline env, "done setup"
    chunked_streaming_response( 200, { 'X-Sleepy-Initial-Delay' => env[:initial_delay].to_s, 'X-Sleepy-Delay' => env[:delay].to_s })
  end

protected
  def timing_info(env)
    {
      :start  => env[:start_time].to_f,
      :delay  => env[:delay],
      :initial_delay => env[:initial_delay],
      :actual => (Time.now.to_f - env[:start_time].to_f)
    }
  end

  def logline env, *args
    env.logger.debug( "timer\t%15.4f\t%7.5f\t%3.2f-%3.2f:\t%s" % [env[:start_time], (Time.now.to_f - env[:start_time]), env[:delay], env[:initial_delay], args.join("\t")])
  end
end
