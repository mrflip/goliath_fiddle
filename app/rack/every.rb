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

class Every < Goliath::API

  def on_close(env)
    env.logger.info "Connection closed."
  end

  def response(env)
    i = 0
    pt = EM.add_periodic_timer(1) do
      env.stream_send("#{i}\n")
      i += 1
    end

    EM.add_timer(10) do
      pt.cancel

      env.stream_send("!! BOOM !!\n")
      env.stream_close
    end

    [200, {}, Goliath::Response::STREAMING]
  end
end
