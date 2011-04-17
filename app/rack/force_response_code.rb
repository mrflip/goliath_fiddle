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
    class ForceResponseCode #  < Goliath::Rack::PostProcessor

      def initialize(app)
        @app = app
      end

      def call(env)
        p ['async.callback', env['async.callback']]
        
        async_cb = env['async.callback']

        env['async.callback'] = Proc.new do |status, headers, body|
           async_cb.call(frp_post_process(env, status, headers, body))
        end
        status, headers, body = @app.call(env)
        frp_post_process(env, status, headers, body)
      end
      
      def frp_post_process(env, status, headers, body)
        p ['frp_post_process', env.params['_force_response_code'], status, headers, body]
        if env.params['_force_response_code'] && status.to_i > 0
          status = env.params['_force_response_code'].to_i
        end
        [status, headers, body]
      end
    end
  end
end
