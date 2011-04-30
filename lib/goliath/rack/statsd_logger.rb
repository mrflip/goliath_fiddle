#!/usr/bin/env ruby
require 'goliath'
require 'gorillib/logger/log'

module Goliath
  module Rack

    #
    # A middleware that performs post-processing
    #
    class PostProcessor
      def initialize(app)
        @app = app
      end

      def call(env)
        async_cb = env['async.callback']

        env['async.callback'] = Proc.new do |status, headers, body|
          async_cb.call(post_process(env, status, headers, body))
        end
        status, headers, body = @app.call(env)
        post_process(env, status, headers, body)
      end

      def post_process(env, status, headers, body)
        [status, headers, body]
      end
    end
  end
end

# Counting: gorets:1|c       # Add 1 to the "gorets" bucket. It stays in memory until the flush interval
# Timing:   glork:320|ms     # The glork took 320ms to complete this time. StatsD figures out 90th percentile, average (mean), lower and upper bounds for the flush interval.
# Sampling: gorets:1|c|@0.1  # Tells StatsD that this counter is being sent sampled every 1/10th of the time.

module Goliath
  module Rack
    class StatsdRequestLogger < Goliath::Rack::PostProcessor
      DEFAULT_HOST = 'localhost'
      DEFAULT_PORT = 8125

      def initialize app, name, options={}
        @name = name
        @host = options[:host] || DEFAULT_HOST
        @port = options[:port] || DEFAULT_PORT

        p [app, name, options, @name, @host, @port]
        super app
      end

      def statsd
        @statsd ||= StatsdSender.open(@host)
      end

      def call(env)
        p [statsd]

        statsd.count [:req_beg, route(env)]
        super(env)
      end

      def route(env)
        env['PATH_INFO'].gsub(%r{^/}, '').gsub(%r{/}, '.')
      end

      def post_process(env, status, headers, body)
        return super if status == -1
        statsd.count [:req_end, route(env)]
        statsd.count [:status, status, route(env)]
        statsd.timing([:req_time, route(env)], (1000 * (Time.now.to_f - env[:start_time].to_f)))
        [status, headers, body]
      end

      # def requests_per_second
      # end
      #
      # def average_latency
      # end
    end
  end
end

class StatsdSender < EventMachine::Connection
  DEFAULT_HOST = '127.0.0.1'
  DEFAULT_PORT = 8125
  DEFAULT_FRAC = 1.0

  def initialize options={}
    @name = options[:name] || 'foo'              # File.basename(Goliath::Application.app_file, '.rb')
    @host = options[:host] || DEFAULT_HOST
    @port = options[:port] || DEFAULT_PORT

    p ['init', @name, @host, @port]
  end

  def name metric=[]
    [@name, metric].flatten.compact.join(".")
  end

  def count metric, val=1, sampling_frac=nil
    # p ['count', @name, @host, @port, metric, val, sampling_frac]
    if sampling_frac && (rand < sampling_frac.to_F)
      send_to_statsd "#{name(metric)}:#{val}|c|@#{sampling_frac}"
    else
      send_to_statsd "#{name(metric)}:#{val}|c"
    end
  end

  def timing metric, val
    send_to_statsd "#{name(metric)}:#{val}|ms"
  end

protected

  def send_to_statsd metric
    send_datagram metric, @host, @port
  end

  def self.open host
    EventMachine::open_datagram_socket(host, 0, self)
  end
end


class StatsdLogger < Goliath::API
  use Goliath::Rack::StatsdRequestLogger, :bob

  def response(env)
    [200, {}, "hello world"]
  end
end
