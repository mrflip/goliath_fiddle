#!/usr/bin/env ruby

#
# A simple HTTP streaming API which returns a 200 response for any GET request
# and then emits numbers 1 through 10 in 1 second intervals, and then closes the
# connection.
#
# A good use case for this pattern would be to provide a stream of updates or a
# 'firehose' like API to stream data back to the clients. Simply hook up to your
# datasource and then stream the data to your clients via HTTP.
#

require 'goliath'
require 'em-synchrony'
require 'em-synchrony/em-http'
require 'em-http-request'

class SonOfABatch < Goliath::API
  use ::Rack::Reloader, 0 if Goliath.dev?

  TARGET_URL         = 'http://127.0.0.1:9001/'

  TARGET_CONCURRENCY = 10
  MAX_TARGET_QUERIES = 100
  TIMEOUT            = 30

  QUERIES = [1.0, 1.5, 2.0, 0.5, 1.0, 0.25]

  def on_close(env)
    env.logger.info "Connection closed."
  end

  def response(env)
    start = Time.now.utc.to_f
    env.logger.debug "iterator #{start}: starting target requests"

    EM::Synchrony::Iterator.new(QUERIES.each_with_index.to_a, TARGET_CONCURRENCY).each do |(delay, idx), iter|
      env.logger.debug "iterator #{start} [#{delay}, #{idx}]: requesting target"
      c = EM::HttpRequest.new("#{TARGET_URL}?wait=#{delay}").aget
      env.logger.debug "iterator #{start} [#{delay}, #{idx}]: requested target"

      # env.stream_send('{"started":"%f","delayed":"%f","now":"%f"}' % [start, delay, Time.now.utc.to_f])
      env.logger.debug "iterator #{start} [#{delay}, #{idx}]: target iter.next"
      c.callback {iter.next}
      env.logger.debug "iterator #{start} [#{delay}, #{idx}]: end target request iter"
    end

    # EM.add_timer(TIMEOUT) do
    # end

    [200, {}, Goliath::Response::STREAMING]
  end
end


# EM::Iterator.new(urls).map(proc{ |url,iter|
#   async_http_get(url){ |res|
#     iter.return(res)
#   }
# }, proc{ |responses|
#   ...
#   puts 'all done!'
# })
