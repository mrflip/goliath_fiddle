#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../vendor/goliath/lib'
$: << File.dirname(__FILE__)+'/../../lib'

require 'goliath'
require 'goliath/plugins/statsd_logger'
require 'goliath/rack/statsd_middleware'
require 'gorillib/logger/log'

# Counting: gorets:1|c       # Add 1 to the "gorets" bucket. It stays in memory until the flush interval
# Timing:   glork:320|ms     # The glork took 320ms to complete this time. StatsD figures out 90th percentile, average (mean), lower and upper bounds for the flush interval.
# Sampling: gorets:1|c|@0.1  # Tells StatsD that this counter is being sent sampled every 1/10th of the time.

class StatsdDemo < Goliath::API
  use    Goliath::Rack::StatsdMiddleware, :statsd_demo
  plugin Goliath::Plugin::StatsdLogger

  def response(env)
    delay = 0.20

    case
    when env['PATH_INFO'] == '/sleepy' then EM::Synchrony.sleep(delay)
    end

    body = { :start => env[:start_time], :delay => delay, :actual => (Time.now.utc.to_f - env[:start_time]) }
    [200, {'X-Responder' => self.class.to_s, 'X-Sleepy-Delay' => delay.to_s, }, body]
  end
end
