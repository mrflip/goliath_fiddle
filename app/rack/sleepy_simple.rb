#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'

require 'boot'
require 'goliath'
require 'rack/abstract_format'
require 'yajl/json_gem'

#
# Wait the amount of time given by the 'delay' parameter before responding (default 2.5, max 15.0).
#
# Handles multiple parallel requests:
#
#   $ ./app/rack/sleepy_simple.rb -sv -p 9002 -e prod &
#   [64277:INFO] 2011-04-24 17:17:31 :: Starting server on 0.0.0.0:9002 in development mode. Watch out for stones.
#
#   $ ab -c100 -n100  'http://127.0.0.1:9002/?delay=3.0'
#
#         Connection Times (ms)
#                       min  mean[+/-sd] median   max
#         Connect:        5    7   1.0      7       9
#         Processing:  3016 3039  16.6   3041    3063
#         Waiting:     3015 3038  16.5   3041    3063
#         Total:       3022 3046  16.4   3050    3069
#
class SleepySimple < Goliath::API
  use Goliath::Rack::Params
  use Rack::AbstractFormat, 'application/json'
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay',         :default => 2.5, :max => 15.0, :min => 0.0, :as => Float}

  def response(env)
    env[:delay] = env.params['delay']

    # EM::Synchrony call allows the reactor to keep spinning: HOORAY CONCURRENCY
    logline env, "sleeping"
    EM::Synchrony.sleep(env[:delay])
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
    env.logger.debug( "timer\t%15.4f\t%7.5f\t%3.2f:\t%s" % [env[:start_time], (Time.now.to_f - env[:start_time]), env[:delay], args.join("\t")])
  end
end
