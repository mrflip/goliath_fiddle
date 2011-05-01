module Goliath
  module Rack
    class StatsdMiddleware
      include Goliath::Rack::AsyncMiddleware

      def initialize app, name
        @name = name
        super(app)
      end

      def call(env)
        agent.count [@name, :req, route(env)]
        super(env)
      end

      def post_process(env, status, headers, body)
        agent.timing [@name, :req_time, route(env)], (1000 * (Time.now.to_f - env[:start_time].to_f))
        agent.timing [@name, :req_time, status],     (1000 * (Time.now.to_f - env[:start_time].to_f))
        [status, headers, body]
      end

      def agent
        Goliath::Plugin::StatsdLogger.agent
      end

      def route(env)
        path = env['PATH_INFO'].gsub(%r{^/}, '')
        return 'root' if path == ''
        path.gsub(%r{/}, '.')
      end
    end
  end
end
