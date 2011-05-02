#!/usr/bin/env ruby
# $: << File.dirname(__FILE__)+'/../../../vendor/goliath/lib'
# $: << File.dirname(__FILE__)+'/../../../lib'

require 'goliath'
require 'em-synchrony/em-http'
require 'gorillib/numeric/clamp'

#
# Here's an example of how to make an asynchronous request in the middleware,
# and only proceed with the response when both the endpoint and our middleware's
# responses have completed.
#
# To run this, start the 'sleepy.rb' server on port 9002:
#
#   ./sleepy.rb -sv -p 9002
#
# And then start the async_aroundware_demo.rb server on port 9000:
#
#   ./async_aroundware_demo.rb -sv -p 9000
#
# Now curl the async_aroundware_demo:
#
#   $ time curl 'http://127.0.0.1:9000/?delay_1=3.4&delay_2=1.0'
#   1: {"start":1304233248.882169,"response_delay":1.0,"initial_delay":0.0,"actual":1.014742136001587}
#   2: {"start":1304233248.8684301,"response_delay":3.4,"initial_delay":0.0,"actual":3.4280998706817627}
#   real	0m3.453s	user	0m0.003s	sys	0m0.004s	pct	0.21
#

BASE_URL     = 'http://localhost:9002/'
HTTP_OPTIONS = { :connect_timeout => 3.0 }

module Logjammin
  def logline env, *args
    tm = Time.now.to_f
    dur = tm - env[:start_time]
    tm = tm - 100 * (tm.to_i / 100)
    env.logger.debug ["%7.5f"%dur, Fiber.current.object_id, *args].map(&:to_s).map(&:chomp).join("\t")
  end
end

#
# This method works, but:
# * It's fairly convoluted
# * I'm not sure if I'm doing the right thing wrt. Fibers in the async.callback Proc
# * I'm getting 'double resume' errors if I attack it with say 100 concurrent requests
# * the direct call to post_process doesn't do anything with the req_1 results
#
module Goliath
  module Rack
    class AsyncAroundware
      include Logjammin

      def initialize app
        @app = app
      end

      def call(env)
        logline env, 'call beg'
        async_cb = env['async.callback']

        # make a non-blocking request
        delay_1 = env.params['delay_1']
        req_1 = EM::HttpRequest.new(BASE_URL, HTTP_OPTIONS).aget(:query => { :delay => delay_1 })

        # the async response chain resumes when req1's response comes back
        env['async.callback'] = Proc.new do |status, headers, body|
          req_1.callback do |c|
            async_cb.call(post_process(env, status, headers, "1: #{body}\n2: #{c.response}"))
            logline env, 'acb  succ'
          end
          req_1.errback do |c|
            async_cb.call(post_process(env, status, headers, "1: #{body}\n2: err: #{c.error}"))
            logline env, 'acb  err'
          end
        end
        
        status, headers, body = @app.call(env) 

        return [status, headers, body] if status && status == Goliath::Connection::AsyncResponse.first
        post_process(env, status, headers, body)
      end

      def post_process(env, status, headers, body)
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
  include Logjammin
  
  def response(env)
    delay_2 = env.params['delay_2']

    logline env, 'req2 beg'
    resp = EM::HttpRequest.new(BASE_URL, HTTP_OPTIONS).get(:query => {:delay => delay_2})
    logline env, 'req2 end'

    [200, { 'X-Delay-2' => (Time.now.to_f - env[:start_time]).to_s }, resp.response]
  end
end
