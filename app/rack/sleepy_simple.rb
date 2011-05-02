#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'

require 'goliath'
require 'rack/abstract_format'

#
# Wait the amount of time given by the 'delay' parameter before responding
# Handles multiple parallel requests -- its EM::Synchrony call allows the
# reactor to keep spinning.
#
class SleepySimple < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay', :max => 5.0, :default => 1.5, :as => Float}
  use Rack::AbstractFormat, 'application/json'

  def response(env)
    start = Time.now.utc.to_f
    delay = env.params['delay']
    env.logger.debug "timer #{start} [#{delay}]: start of response"

    # EM::Synchrony call allows the reactor to keep spinning: HOORAY CONCURRENCY
    EM::Synchrony.sleep(delay)
    body = { :start => start, :delay => delay, :actual => (Time.now.utc.to_f - start) }

    env.logger.debug "timer #{start} [#{delay}]: after sleep: #{body.inspect}"
    [200, {'X-Responder' => self.class.to_s, 'X-Sleepy-Delay' => delay.to_s, }, body]
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
