require 'goliath'
require 'em-synchrony/em-http'
require 'yaml'

class Proxy < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use ::Rack::Reloader, 0 if Goliath.dev?

  TARGET_URL         = 'http://127.0.0.1:9001/?delay=2.5'

  def response(env)
    gh = EM::HttpRequest.new(TARGET_URL).get
    logger.info "Received #{gh.to_yaml}"
    logger.info "Received #{gh.response_header.status} from downstream: #{gh.response.class} #{gh.response.to_s}"

    [200, {'X-Goliath-Responder' => self.class.to_s}, gh.response]
  end
end

# > gem install em-http-request --pre
# > gem install em-synchrony --pre
#
# > ruby github.rb -sv -p 9000
# > Starting server on 0.0.0.0:9000 in development mode. Watch out for stones.
#
# > curl -vv "localhost:9000/?query=ruby"

