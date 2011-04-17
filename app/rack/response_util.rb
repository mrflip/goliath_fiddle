require 'logger'
require 'goliath'
require 'yajl/json_gem'

require 'em-synchrony/em-http'

$: << File.dirname(__FILE__)
require 'force_response_code'

#
# This responder will wait a given amount of time before responding -- yet can
# handle multiple parallel requests.
#
class ResponseUtil < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::ForceResponseCode  # let requestor set response code
  use ::Rack::Reloader, 0 if Goliath.dev?

  TARGET_URL_BASE = "http://localhost:9000"

  def response(env)
    start = Time.now.utc.to_f

    env.logger.debug "timer #{start}: start of response"

    multi = EM::Synchrony::Multi.new
    multi.add :page1, EM::HttpRequest.new("#{TARGET_URL_BASE}/?delay=2.0").aget
    multi.add :page2, EM::HttpRequest.new("#{TARGET_URL_BASE}/?delay=1.0").aget
    multi.add :page3, EM::HttpRequest.new("#{TARGET_URL_BASE}/?delay=2.5").aget
    multi.add :page4, EM::HttpRequest.new("#{TARGET_URL_BASE}/?delay=0.5").aget

    env.logger.debug "timer #{start}: before perform"
    data = multi.perform

    results = { :results => {} , :errors => {} }
    data.responses.each do |resp_type, resp_hsh|
      resp_type = (resp_type == :callbacks) ? :results : :errors
      resp_hsh.each do |req,resp|
        parsed = JSON.parse(resp.response) rescue resp.response
        results[:results][req] = [resp.response_header.http_status, resp.response_header.to_hash, parsed]
      end
    end

    env.logger.debug "timer #{start}: after fetch"

    now = Time.now.utc.to_f ; actual = now - start
    body = results.merge(:started => start, :actual => actual, :now => now).to_json + "\n"
    [200, {'X-Goliath-Responder' => self.class.to_s }, body]
  end
end
