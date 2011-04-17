module Goliath
  module Rack

    #
    # A middleware that performs post-processing
    #
    class PostProcessor
      def initialize(app)
        @app = app
      end

      def call(env)
        async_cb = env['async.callback']

        env['async.callback'] = Proc.new do |status, headers, body|
          async_cb.call(post_process(env, status, headers, body))
        end
        status, headers, body = @app.call(env)
        post_process(env, status, headers, body)
      end

      def post_process(env, status, headers, body)
        [status, headers, body]
      end
    end
  end
end
