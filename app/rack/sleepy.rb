require 'logger'
require 'goliath'
require 'yajl/json_gem'

#
# This responder will wait a given amount of time before responding -- yet can
# handle multiple parallel requests.
#
class Sleepy < Goliath::API
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

    env.logger.debug "timer #{start} [#{delay}]: start of response"

    EM::Synchrony.sleep(delay)

    env.logger.debug "timer #{start} [#{delay}]: after sleep"

    now = Time.now.utc.to_f ; actual = now - start
    body = '{"started":%f,"delay":%f,"actual":%f,"now":%f}' % [start, delay, actual, now]
    [200, {'X-Goliath-Responder' => self.class.to_s, 'X-Sleepy-Delay' => delay.to_s }, body]
  end
end

#
# Proof of concurrency!
#
# $ ruby app/rack/sleepy.rb -sv -p 9000
# $ ab -c 10 -n 50  'http://127.0.0.1:9000/?delay=2.0'
# This is ApacheBench, Version 2.3 <$Revision: 655654 $>
# Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
# Licensed to The Apache Software Foundation, http://www.apache.org/
#
# Benchmarking 127.0.0.1 (be patient).....done
#
#
# Server Software:        Goliath
# Server Hostname:        127.0.0.1
# Server Port:            9000
#
# Document Path:          /?delay=2.0
# Document Length:        88 bytes
#
# Concurrency Level:      10
# Time taken for tests:   10.117 seconds
# Complete requests:      50
# Failed requests:        0
# Write errors:           0
# Total transferred:      11550 bytes
# HTML transferred:       4400 bytes
# Requests per second:    4.94 [#/sec] (mean)
# Time per request:       2023.306 [ms] (mean)
# Time per request:       202.331 [ms] (mean, across all concurrent requests)
# Transfer rate:          1.11 [Kbytes/sec] received
#
# Connection Times (ms)
#               min  mean[+/-sd] median   max
# Connect:        0    0   0.1      0       1
# Processing:  2004 2018  11.0   2017    2044
# Waiting:     2004 2018  11.0   2017    2044
# Total:       2004 2018  11.0   2018    2044
#
# Percentage of the requests served within a certain time (ms)
#   50%   2018
#   66%   2025
#   75%   2028
#   80%   2029
#   90%   2032
#   95%   2036
#   98%   2044
#   99%   2044
#  100%   2044 (longest request)
