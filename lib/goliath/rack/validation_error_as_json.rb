module Goliath
  module Rack

    # Middleware to catch {Goliath::Validation::Error} exceptions
    # and returns the [status code, no headers, :error => exception message]
    #
    # @option opts [Boolean] :force_json Normally ValidationError returns a hash
    #   as body (which presumes you're using Rack::Render). Specify :force_json =>
    #   true to sets the Content-Type header to 'application/json' and return a
    #   json string.  You must require some sort of json lib or another.
    #
    class ValidationErrorAsJson < ValidationError

      def call(env)
        begin
          @app.call(env)
        rescue Goliath::Validation::Error => e
          env.logger.debug([env['REQUEST_URI'], e.class, e.status_code, e.message].inspect) if env.respond_to?(:logger)
          [e.status_code, {'Content-Type' => 'application/json'}, {:error => e.message}.to_json]
        end
      end
    end
  end
end
