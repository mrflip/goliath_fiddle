#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'

require 'goliath'
require 'em-synchrony/em-http'
require 'yajl/json_gem'
require 'goliath/synchrony/multi_receiver'
require 'goliath/rack/async_aroundware'

#
# Here's a way to make an asynchronous request in the middleware, and only
# proceed with the response when both the endpoint and our middleware's
# responses have completed.
#
# To run this, start the 'sleepy.rb' server on port 9002:
#
#   ./sleepy.rb -sv -p 9002
#
# And then start the async_aroundware_demo_multi.rb server on port 9000:
#
#   ./async_aroundware_demo_multi.rb -sv -p 9000
#
# Now curl the async_aroundware_demo_multi:
#
#    $ time curl  'http://127.0.0.1:9000/?delay_1=1.0&delay_2=1.5'
#    {"results":{"sleep_2":[1304405129.793657,1.5,1.5003128051757812],"sleep_1":[1304405129.793349,1.0,1.000417947769165]},"errors":{}}
#

BASE_URL     = 'http://localhost:9002/'

class MyResponseReceiver < Goliath::Synchrony::MultiReceiver
  def pre_process
    add :sleep_1, EM::HttpRequest.new("#{BASE_URL}?delay=#{env.params['delay_1']}").aget
  end

  def post_process
    results = { :results => { :sleep_2 => body }, :errors => {} }
    responses[:callback].each{|name, resp| results[:results][name] = JSON.parse(resp.response) }
    responses[:errback ].each{|name, err|  results[:errors][name]  = err.error     }
    [status, headers, JSON.generate(results)]
  end
end

class AsyncAroundwareDemoMulti < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay_1', :default => 1.0, :max => 5.0, :min => 0.0, :as => Float}
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay_2', :default => 0.5, :max => 5.0, :min => 0.0, :as => Float}
  #
  use Goliath::Rack::AsyncAroundware, MyResponseReceiver

  def response(env)
    resp = EM::HttpRequest.new("#{BASE_URL}?delay=#{env.params['delay_2']}").get

    [200, { }, JSON.parse(resp.response)]
  end
end
