require 'time'
require 'rack/mime'
Rack::Mime::MIME_TYPES['.ico'] = 'image/x-icon'

module Goliath
  module Rack
    #
    #
    class StaticFiles
      def initialize app, opts={}
        @app       = app
        @public    = opts[:public] || Goliath.root_path('public')
        @cache_age = opts[:cache_age]
      end

      def call(env)
        path = env['PATH_INFO'].gsub(%r{(.+)/$}, '\1')
        info = static_file(path)
        return @app.call(env) unless info

        body, mime_type = info
        headers = {'X-Responder' => self.class.to_s, 'Content-Type' => mime_type }
        if @cache_age
          headers['Cache-Control'] = "public, max-age=#{@cache_age.to_i}"
          headers['Expires'] = Time.at(Time.now.to_i + @cache_age).utc.httpdate
        end
        [200, headers, body]
      end

      def static_file path
        return nil unless path =~ %r{^((?:\/[\w\-\.]+)*?)/([\w\-\.]+)(\.\w+)$}
        dirname, basename, ext = [$1, $2, $3]

        static_filename = File.join(@public, path)
        return nil unless File.exist?(static_filename)

        mime_type = ::Rack::Mime.mime_type(ext)
        [File.read(static_filename), mime_type]
      end
    end
  end
end
