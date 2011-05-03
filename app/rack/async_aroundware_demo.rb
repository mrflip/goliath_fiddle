#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'

require 'goliath'
require 'em-synchrony/em-http'
require 'yajl/json_gem'

require 'logjammin'

BASE_URL     = 'http://localhost:9002/'

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
#   real        0m3.453s        user    0m0.003s        sys     0m0.004s        pct     0.21
#

#
# It would be swell if this works -- it doesn't, because barrier.perform yields
# in the wrong fiber to be resumable by the barrier.add callback
#
class AsyncAroundware
  include Logjammin
  include Goliath::Rack::AsyncMiddleware

  def call(env)
    logline env, 'call beg'
    barrier = EM::Synchrony::MultiWithLogging.new(env)

    # make a non-blocking request
    logline env, 'req1 beg'
    barrier.add :sleep_1, EM::HttpRequest.new("#{BASE_URL}?delay=#{env.params['delay_1']}").aget
    logline env, 'req1 created'

    super(env, barrier)
  end

  def post_process(env, status, headers, body, barrier)
    # this breaks, because fiber mismatch to barrier.add
    logline env, 'barrier beg'
    barrier.perform
    logline env, 'barrier end'

    results = { :results => { :sleep_2 => body }, :errors => {} }
    barrier.responses[:callback].each{|name, resp| results[:results][name] = JSON.parse(resp.response) }
    barrier.responses[:errback ].each{|name, err|  results[:errors][name]  = err.error     }

    [status, headers, JSON.pretty_generate(results)]
  end
end

#
# This method works, but it's fairly convoluted
#
# Also you'll get 'double resume' errors if you attack it with say 100 concurrent requests
#
class AsyncAroundwareWithCallback < AsyncAroundware

  def call(env, *args, &block)
    async_cb = env['async.callback']
    logline(env, 'call beg')

    barrier = EM::Synchrony::MultiWithLogging.new(env)

    # make a non-blocking request
    logline env, 'req1 beg'
    barrier.add :sleep_1, EM::HttpRequest.new("#{BASE_URL}?delay=#{env.params['delay_1']}").aget
    logline env, 'req1 created'

    env['async.callback'] = Proc.new do |status, headers, body|
      barrier.callback do
        async_cb.call(post_process(env, status, headers, body, barrier))
      end
    end

    status, headers, body = @app.call(env)
    if status == Goliath::Connection::AsyncResponse.first
      [status, headers, body]
    else
      post_process(env, status, headers, body, barrier)
    end
  end
end


class AsyncAroundwareDemo < Goliath::API
  include Logjammin
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay_1', :default => 1.0, :max => 5.0, :min => 0.0, :as => Float}
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay_2', :default => 0.5, :max => 5.0, :min => 0.0, :as => Float}
  #
  use AsyncAroundwareWithCallback

  def response(env)
    logline env, 'req2 beg'
    resp = EM::HttpRequest.new("#{BASE_URL}?delay=#{env.params['delay_2']}").get
    logline env, 'req2 end'

    [200, { }, JSON.parse(resp.response)]
  end
end

