#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'

require 'goliath'
require 'em-synchrony/em-http'
require 'yajl/json_gem'

require 'logjammin'

BASE_URL     = 'http://localhost:9002/'

class EM::Synchrony::MultiWithAcb < EM::Synchrony::Multi
  include Logjammin
  attr_accessor :status, :headers, :body
  def shb() [status, headers, body] end

  def initialize env, async_callback
    @env = env
    @acb = async_callback
    @received_response = false
    super()
  end

  def add(name, conn)
    fiber = Fiber.current
    conn.callback { logline(@env, 'mcb  success') ; @responses[:callback][name] = conn; check_progress(fiber) }
    conn.errback  { logline(@env, 'mcb  error')   ; @responses[:errback][name]  = conn; check_progress(fiber) }
    @requests.push(conn)
  end

  def call shb
    status, headers, body = shb
    logline @env, 'barrier call', status, body
    @received_response = true
    @status, @headers, @body = status, headers, body
    succeed if finished?
  end

  def finished?
    fin = super
    logline(@env, 'finished?', fin, @received_response) ;
    fin && @received_response
  end

  def perform
    logline(@env, 'perform') ;
    super
  end

protected

  def check_progress(fiber)
    logline(@env, 'check prog', fiber.alive?, fiber != Fiber.current, fiber.object_id, Fiber.current.object_id)
    super
  end
end

class DeferredResponse
  def initialize 
  end
end

class AsyncAroundware
  include Logjammin
  include Goliath::Rack::AsyncMiddleware

  def call(env, *args, &block)
    logline(env, 'call beg')

    async_cb = env['async.callback']
    barrier = EM::Synchrony::MultiWithAcb.new(env, async_cb)
    env['async.callback'] = barrier
    barrier.callback do
      logline env, 'barrier cb'
      async_cb.call(post_process(env, barrier))
    end

    # make a non-blocking request
    logline env, 'req1 beg'
    barrier.add :sleep_1, EM::HttpRequest.new("#{BASE_URL}?delay=#{env.params['delay_1']}").aget
    logline env, 'req1 created'

    status, headers, body = @app.call(env)
    if status == Goliath::Connection::AsyncResponse.first
      logline env, 'async resp'
      [status, headers, body]
    else
      barrier.call(status, headers, body)
      logline env, 'barrier beg', barrier.responses
      barrier.perform
      logline env, 'barrier end', barrier.responses
      post_process(env, barrier)
    end
  end

  def post_process(env, barrier)
    status, headers, body = barrier.shb

    results = { :results => { :sleep_2 => body }, :errors => {} }
    barrier.responses[:callback].each{|name, resp| results[:results][name] = JSON.parse(resp.response) }
    barrier.responses[:errback ].each{|name, err|  results[:errors][name]  = err.error     }

    [status, headers, JSON.pretty_generate(results)]
  end
end


class AsyncAroundwareDemoMulti < Goliath::API
  include Logjammin
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay_1', :default => 1.0, :max => 5.0, :min => 0.0, :as => Float}
  use Goliath::Rack::Validation::NumericRange, {:key => 'delay_2', :default => 0.5, :max => 5.0, :min => 0.0, :as => Float}
  #
  use AsyncAroundware

  def response(env)
    logline env, 'req2 beg'
    resp = EM::HttpRequest.new("#{BASE_URL}?delay=#{env.params['delay_2']}").get
    logline env, 'req2 end'

    raise 'hell'
    
    [200, { }, JSON.parse(resp.response)]
  end
end
