require 'goliath/validation/standard_http_errors'
require 'goliath/rack/post_processor'

module Goliath
  module Rack
    # 
    # If the ++_force_status++ param is given, force the HTTP response status to
    # that value. (Note the leading _underscore on ++_force_status++)
    #
    # Sets headers ++X-Force-Status-To++ and ++X-Force-Status-Was++ to the
    # forced and former status code respectively.
    #
    # _force_status must be > 0 if present; this does no sanity checking otherwise
    #
    class ForceStatus < Goliath::Rack::PostProcessor
      def call(env)
        return @app.call(env) if env.params['_force_status'].to_i == 0
        raise Goliath::Validation::BadRequestError if env.params['_force_status'].to_i < 0
        super
      end
      
      def post_process(env, status, headers, body)
        new_status = env.params['_force_status'].to_i
        headers.merge! 'X-Force-Status-Was' => status.to_s, 'X-Force-Status-To' => new_status.to_s
        [new_status, headers, body]
      end
    end
  end
end
