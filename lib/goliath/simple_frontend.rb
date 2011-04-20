require 'haml'
require 'tilt'

require Goliath.root_path('app/helpers/main')

#
# Renders a templated view
#
class Goliath::SimpleFrontend < Goliath::API

protected

  # Renders a HAML template from the 'app/views' directory. File must have the
  # .haml extension
  #
  # @option [Symbol] template The base name of the file to use
  # @option [Hash] locals Local variables to pass to the templating engine
  #
  # @example body = haml :root   # renders app/views/root.haml
  def haml template, locals={}
    layout   = Tilt.new(Goliath.root_path("app/views/layout.haml"))
    template = Tilt.new(Goliath.root_path("app/views/#{template}.haml"))
    layout.render(self, locals) do
      template.render(self, locals)
    end
  end

  # Bone-simple html page.
  # @param text [String] body of page. No escaping or anything else is done.
  # @option options [Hash]   :head      Tag + content pairs to stuff in head
  # @option options [String] :head_text raw content to stuff in head
  # @option options [String] :foot_text raw content to stuff at end of body
  def html_page text, options = {}
    page = ["<html><head>"]
    page << options[:head_text]
    page << "</head><body>"
    page << text
    page << options[:foot_text]
    page << "</body></html>"
    page.join("\n")
  end
end
