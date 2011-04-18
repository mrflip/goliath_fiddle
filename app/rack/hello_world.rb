require 'goliath'

class HelloWorld < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Formatters::JSON   # JSON output formatter

  def response(env)
    logger.info "Hello, world"
    [200, {'X-Responder' => self.class.to_s}, { "result" => "Hello there, world" }]
  end
end

