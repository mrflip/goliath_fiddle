require 'logger'
require 'goliath'
require 'yajl/json_gem'

#
# This responder will wait a given amount of time before responding -- yet can
# handle multiple parallel requests.
#
class SleepyCallback < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  # use Goliath::Rack::Formatters::JSON   # JSON output formatter
  # use Goliath::Rack::Render             # auto-negotiate response format
  # use Goliath::Rack::ValidationError    # catch and render validation errors
  use ::Rack::Reloader, 0 if Goliath.dev?

  # longest allowable delay
  MAX_DELAY    = 5.0

  def response(env)
    start = Time.now.utc.to_f

    delay = (env.params['delay'] || 1.0).to_f
    delay = MAX_DELAY if delay > MAX_DELAY
    env.logger.debug "timer #{start} [#{delay}]: before launching response"

    # EM.next_tick{ env.stream_send('{"started":%f,"stream_started":%f' % [start, Time.now.utc.to_f]) }

    tt = EM.add_timer(delay) do
      env.logger.debug "timer #{start} [#{delay}]: timer fired"
      now = Time.now.utc.to_f
      ('{"started":%f,"delay":%f,"actual":%f,"now":%f}' % [start, delay, now - start, now])
    end
    env.logger.debug "timer #{start} [#{delay}]: after launching response"
    
    [200, {'X-Goliath-Responder' => self.class.to_s, 'X-Sleepy-Delay' => delay.to_s }, tt.callback]
  end
end

# Proof of concurrency!
#
# $ ruby app/rack/sleepy.rb -sv -p 9001
# $ ab -c 100 -n 100  'http://127.0.0.1:9001/?delay=2.5'
#
# This is ApacheBench, Version 2.3 <$Revision: 655654 $>
# Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
# Licensed to The Apache Software Foundation, http://www.apache.org/
#
# Benchmarking 127.0.0.1 (be patient)...
#
# Server Software:        Goliath
# Server Hostname:        127.0.0.1
# Server Port:            9001
#
# Document Path:          /?delay=2.5
# Document Length:        77 bytes
#
# Concurrency Level:      100
# Time taken for tests:   3.001 seconds
# Complete requests:      100
# Failed requests:        0
# Write errors:           0
# Total transferred:      15000 bytes
# HTML transferred:       7700 bytes
# Requests per second:    33.33 [#/sec] (mean)
# Time per request:       3000.705 [ms] (mean)
# Time per request:       30.007 [ms] (mean, across all concurrent requests)
# Transfer rate:          4.88 [Kbytes/sec] received
#
# Connection Times (ms)
#               min  mean[+/-sd] median   max
# Connect:        2    4   1.0      5       6
# Processing:  2506 2756 145.6   2744    2993
# Waiting:       15  488  47.8    492     493
# Total:       2512 2760 144.6   2749    2995
#
# Percentage of the requests served within a certain time (ms)
#   50%   2749
#   66%   2841
#   75%   2879
#   80%   2928
#   90%   2962
#   95%   2979
#   98%   2989
#   99%   2995
#  100%   2995 (longest request)
