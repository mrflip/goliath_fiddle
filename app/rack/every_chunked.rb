#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'goliath'

$: << File.dirname(__FILE__)+'/../../lib'
require 'goliath/chunked_streaming_api'

#
# A simple HTTP streaming API which returns a 200 response for any GET request
# and then uses Chunked transfer encoding to emits numbers 1 through 10 in 1
# second intervals, and finally closes the connection.
#
class EveryChunked < Goliath::ChunkedStreamingAPI
  def response(env)
    i = 0
    pt = EM.add_periodic_timer(1) do
      send_chunk(env, "#{i}\n")
      i += 1
    end

    EM.add_timer(10) do
      pt.cancel
      send_chunk(env, "!! lé böøm !!")
      close_stream(env)
    end
    
    headers = { 'Content-Type' => 'text/plain', 'X-Responder' => self.class.to_s }
    [200, STREAMING_HEADERS.merge(headers), STREAMING]
  end

  def on_close(env)
    env.logger.info "Connection closed."
  end
end
