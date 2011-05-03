#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'

require 'goliath'
require 'em-synchrony/em-http'
require 'yajl/json_gem'
require 'async_aroundware.rb'

BASE_URL     = 'http://localhost:9002/'

class MyBarrier < Barrier
  def pre_process
    add :sleep_1, EM::HttpRequest.new("#{BASE_URL}?delay=#{env.params['delay_1']}").aget
  end

  def post_process
    results = { :results => { :sleep_2 => body }, :errors => {} }
    responses[:callback].each{|name, resp| results[:results][name] = JSON.parse(resp.response) }
    responses[:errback ].each{|name, err|  results[:errors][name]  = err.error     }
    [status, headers, JSON.pretty_generate(results)]
  end
end


class AsyncAroundwareDemoMulti < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay_1', :default => 1.0, :max => 5.0, :min => 0.0, :as => Float}
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay_2', :default => 0.5, :max => 5.0, :min => 0.0, :as => Float}
  #
  use AsyncAroundware, MyBarrier

  def response(env)
    resp = EM::HttpRequest.new("#{BASE_URL}?delay=#{env.params['delay_2']}").get

    [200, { }, JSON.parse(resp.response)]
  end
end
