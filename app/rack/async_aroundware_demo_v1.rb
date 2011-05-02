#!/usr/bin/env ruby
# $: << File.dirname(__FILE__)+'/../../../vendor/goliath/lib'
# $: << File.dirname(__FILE__)+'/../../../lib'

require 'goliath'
require 'em-synchrony/em-http'
require 'gorillib/numeric/clamp'

BASE_URL     = 'http://localhost:9002/'
HTTP_OPTIONS = { :connect_timeout => 3.0 }

module Goliath
  module Rack
    class AsyncAroundware
      def initialize(app)
        @app = app
      end

      def logline env, *args
        tm = Time.now.to_f
        dur = tm - env[:start_time]
        tm = tm - 100 * (tm.to_i / 100)
        env.logger.debug ["%7.5f"%dur, *args].map(&:to_s).map(&:chomp).join("\t")
      end

      def call(env)
        logline env, '------------'
        logline env, '--- YO -----'
        async_cb = env['async.callback']

        delay_1 = env.params['delay_1']

        logline env, 'req  beg '
        # make a long-running request
        req_1 = EM::HttpRequest.new(BASE_URL, HTTP_OPTIONS).aget(:query => { :delay => delay_1 })
        logline env, 'req  end '

        env['async.callback'] = Proc.new do |status, headers, body|
          logline env, 'acb  beg ', status, body

          req_1.callback do |c|
            logline env, 'r2cb beg ', status, body, c.response
            status, headers, body = post_process(env, status, headers, body)

            logline env, 'r2cb chn ', status, body, 1
            ret = async_cb.call(status, headers, body)

            logline env, 'r2cb end ', ret.inspect
            ret
          end

          logline env, 'acb  end ', status, body
          [status, headers, body]
        end
        
        logline env, '@app call'
        status, headers, body = @app.call(env) 

        logline env, 'call pp  ', status, body
        return [status, headers, body] if status && status == Goliath::Connection::AsyncResponse.first
        shb = post_process(env, status, headers, body)
        logline env, 'call end ', status, body
        shb
      end

      def post_process(env, status, headers, body)
        logline env, 'pp   beg ', status, body
        [status, headers, body]
      end
    end
  end
end


class AsyncAroundwareDemo < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay_1', :default => 1.0, :max => 5.0, :min => 0.0, :as => Float}
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay_2', :default => 0.5, :max => 5.0, :min => 0.0, :as => Float}
  use Goliath::Rack::AsyncAroundware

  def logline env, *args
    tm = Time.now.to_f
    dur = tm - env[:start_time]
    tm = tm - 100 * (tm.to_i / 100)
    env.logger.debug ["%7.5f"%dur, *args].join("\t").chomp
  end
  
  def response(env)
    delay_2 = env.params['delay_2']

    logline env, 'req2 beg'
    resp = EM::HttpRequest.new(BASE_URL, HTTP_OPTIONS).get(:query => {:delay => delay_2})
    logline env, 'req2 end'

    [200, { 'X-Delay-2' => (Time.now.to_f - env[:start_time]).to_s }, resp.response]
  end
end
