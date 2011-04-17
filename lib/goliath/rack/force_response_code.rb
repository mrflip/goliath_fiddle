
module Goliath
  HTTP_ERROR_CODES = HTTP_STATUS_CODES.select{|code,msg| code >= 400 && code <= 599 }
  HTTP_ERROR_CODES.each do |code, msg|
    Goliath::Validation.const_set msg.gsub(/\W+/, '')+'Error', Goliath::Validation::Error.new(code, msg)
  end
end

module Goliath
  module Rack

    # #
    # # A middleware that performs post-processing
    # #
    # class PostProcessor
    #   def initialize(app)
    #     @app = app
    #   end
    # 
    #   def call(env)
    #     async_cb = env['async.callback']
    # 
    #     env['async.callback'] = Proc.new do |status, headers, body|
    #       async_cb.call(post_process(env, status, headers, body))
    #     end
    #     status, headers, body = @app.call(env)
    #     post_process(env, status, headers, body)
    #   end
    # 
    #   def post_process(env, status, headers, body)
    #     [status, headers, body]
    #   end
    # end
    
    # 
    # If a _force_response_code param is included in the request, the
    # ForceResponseCode middleware will force the response code to the given
    # value no matter what happens downstream
    #
    # Note: this does no sanity checking on the code you specify, other than
    # forcing it to be > 0.
    #
    class ForceResponseCode #  < Goliath::Rack::PostProcessor

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) if env.params['_force_response_code'].to_i == 0
        raise Goliath::Validation::BadRequestError if env.params['_force_response_code'].to_i < 0
        
        async_cb = env['async.callback']

        env['async.callback'] = Proc.new do |status, headers, body|
           async_cb.call(frp_post_process(env, status, headers, body))
        end
        status, headers, body = @app.call(env)
        frp_post_process(env, status, headers, body)
      end
      
      def frp_post_process(env, status, headers, body)
        status = env.params['_force_response_code'].to_i
        [status, headers, body]
      end
    end
  end
end
