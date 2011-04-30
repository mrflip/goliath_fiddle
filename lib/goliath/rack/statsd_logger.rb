#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../../vendor/goliath/lib'
$: << File.dirname(__FILE__)+'/../../../lib'

require 'goliath'
require 'goliath/plugins/statsd_logger'
require 'gorillib/logger/log'

# Counting: gorets:1|c       # Add 1 to the "gorets" bucket. It stays in memory until the flush interval
# Timing:   glork:320|ms     # The glork took 320ms to complete this time. StatsD figures out 90th percentile, average (mean), lower and upper bounds for the flush interval.
# Sampling: gorets:1|c|@0.1  # Tells StatsD that this counter is being sent sampled every 1/10th of the time.

module Goliath
  module Rack
    class StatsdRequestLogger
      include Goliath::Rack::AsyncMiddleware

      def initialize app, name
        @name = name
        super(app)
      end

      def call(env)
        agent.count [@name, :req, route(env)]
        super(env)
      end

      def post_process(env, status, headers, body)
        agent.timing [@name, :req_time, route(env)], (1000 * (Time.now.to_f - env[:start_time].to_f))
        agent.timing [@name, :req_time, status],     (1000 * (Time.now.to_f - env[:start_time].to_f))
        [status, headers, body]
      end

      def agent
        Goliath::Plugin::StatsdLogger.agent
      end

      def route(env)
        path = env['PATH_INFO'].gsub(%r{^/}, '')
        return 'root' if path == ''
        path.gsub(%r{/}, '.')
      end
    end
  end
end

class StatsdLogger < Goliath::API
  use    Goliath::Rack::StatsdRequestLogger, :bob
  plugin Goliath::Plugin::StatsdLogger

  def response(env)
    delay = 1.0

    case
    when env['PATH_INFO'] == '/sleepy' then EM::Synchrony.sleep(delay)
    end

    body = { :start => env[:start_time], :delay => delay, :actual => (Time.now.utc.to_f - env[:start_time]) }
    [200, {'X-Responder' => self.class.to_s, 'X-Sleepy-Delay' => delay.to_s, }, body]
  end
end
