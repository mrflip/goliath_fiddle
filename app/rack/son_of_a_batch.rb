#!/usr/bin/env ruby

require 'goliath'
require 'em-synchrony'
require 'em-synchrony/em-http'
require 'em-http-request'

$: << File.dirname(__FILE__)+'/../../lib'
require 'goliath/chunked_streaming_api'

class SonOfABatch < Goliath::ChunkedStreamingAPI

  TARGET_URL         = 'http://127.0.0.1:9001/'

  TARGET_CONCURRENCY = 10
  MAX_TARGET_QUERIES = 100
  TIMEOUT            = 30

  QUERIES = [1.0, 1.5, 2.0, 0.5, 1.0, 0.25]

  def response(env)
    start = Time.now.utc.to_f
    env.logger.debug "iterator #{start}: starting target requests"

    EM::Synchrony::Iterator.new(QUERIES.each_with_index.to_a, TARGET_CONCURRENCY).each(
      proc{|(delay, idx), iter|

        env.logger.debug "iterator #{start} [#{delay}, #{idx}]: requesting target"
        c = EM::HttpRequest.new("#{TARGET_URL}?wait=#{delay}").aget
        env.logger.debug "iterator #{start} [#{delay}, #{idx}]: requested target"

        c.callback do
          send_chunk(env, c.response+"\n")
          env.logger.debug "iterator #{start} [#{delay}, #{idx}]: target iter.next"
          iter.next
        end

        env.logger.debug "iterator #{start} [#{delay}, #{idx}]: end target request iter"

      }, proc{|responses|
        env.logger.debug "iterator #{start}: closing stream"
        close_stream(env)
      })

    headers = { 'Content-Type' => 'text/plain', 'X-Responder' => self.class.to_s }
    [200, Goliath::Response::STREAMING_HEADERS.merge(headers), Goliath::Response::STREAMING]
  end
end
