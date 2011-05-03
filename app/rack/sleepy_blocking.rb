#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'

require 'boot'
require 'goliath'
require 'rack/abstract_format'
require 'yajl/json_gem'

#
# Wait the amount of time given by the 'delay' parameter before responding (default 2.5, max 15.0).
#
#
#
# Cannot handle multiple parallel requests -- its sleep call blocks the reactor,
# the WRONG thing for a goliath endpoint
#
#   $ ./app/rack/sleepy_blocking.rb -sv -p 9002 -e prod &
#   [64277:INFO] 2011-04-24 17:17:31 :: Starting server on 0.0.0.0:9002 in development mode. Watch out for stones.
#
#   $ ab -c5 -n5  'http://127.0.0.1:9002/?delay=3.0'
#
#         Connection Times (ms)
#                       min  mean[+/-sd] median   max
#         Connect:        0    0   0.0      0       0
#         Processing: 15008 15008   0.0  15008   15008
#         Waiting:    15008 15008   0.0  15008   15008
#         Total:      15008 15008   0.0  15008   15009
#
class SleepyBlocking < Goliath::API
  use Goliath::Rack::Params
  use Rack::AbstractFormat, 'application/json'
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay',         :default => 2.5, :max => 15.0, :min => 0.0, :as => Float}

  def response(env)
    env[:delay] = env.params['delay']

    #  This call call **blocks the reactor**, the **WRONG** thing for a goliath endpoint
    logline env, "sleeping"
    sleep env[:delay]
    logline env, "after sleep"

    logline env, "sending result"
    [ 200, { 'X-Sleepy-Delay' => env[:delay].to_s }, JSON.generate(timing_info(env)) ]
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
