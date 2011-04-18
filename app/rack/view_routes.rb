require 'goliath'
require 'haml'
require 'tilt'
require 'rack/mime'
unless defined?(ROOT_DIR) then
  ROOT_DIR = File.expand_path(File.dirname(__FILE__)+'/../..')
  $: << ROOT_DIR+'/lib'
end
require 'goliath/validation/standard_http_errors'

Rack::Mime::MIME_TYPES['.ico'] = 'image/x-icon'

#
# Renders a templated view
#
class ViewRoutes < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::ValidationError    # auto-negotiate response format
  use Goliath::Rack::Render             # auto-negotiate response format

  def response(env)
    path    = env['REQUEST_PATH']
    headers = {'X-Responder' => self.class.to_s, 'Content-Type' => 'text/html' }

    case
    when path =~ %r{^/hi/?$}
      body = html_page("<h1>Howdy!</hi>", :head => { :title => "Hello, there" })
    when info = static_file(path)
      contents, mime_type = info
      headers['Content-Type'] = mime_type
      body = contents
    when path == "/"
      body = haml :root
    else
      raise Goliath::Validation::NotFound
    end

    [200, headers, body]
  end


protected

  # Renders a HAML template from the 'app/views' directory. File must have the
  # .haml extension
  #
  # @option [Symbol] template The base name of the file to use
  # @option [Hash] locals Local variables to pass to the templating engine
  #
  # @example body = haml :root   # renders app/views/root.haml
  def haml template, locals={}
    layout   = Tilt.new(root_path("app/views/layout.haml"))
    template = Tilt.new(root_path("app/views/#{template}.haml"))
    layout.render(locals) do
      template.render(locals)
    end
  end

  # Bone-simple html page.
  # @param text [String] body of page. No escaping or anything else is done.
  # @option options [Hash]   :head      Tag + content pairs to stuff in head
  # @option options [String] :head_text raw content to stuff in head
  # @option options [String] :foot_text raw content to stuff at end of body
  def html_page text, options = {}
    page = ["<html><head>"]
    (options[:head] || {}).each{|k,v| page << "<#{k}>#{v}</#{k}>"}
    page << options[:head_text]
    page << "</head><body>"
    page << text
    page << options[:foot_text]
    page << "</body></html>"
    page.join("\n")
  end

  def self.root_path *dirs
    File.join(ROOT_DIR, *dirs)
  end
  def root_path(*args) self.class.root_path(*args) end

  def static_file path
    return nil unless path =~ %r{^/(.*?)/?([\w\-\.]+)(\.\w+)$}
    dirname, basename, ext = [$1, $2, $3]
    mime_type = Rack::Mime.mime_type(ext)
    static_filename = Dir[root_path('public', path)].first
    [File.read(static_filename), mime_type]
  end
end
