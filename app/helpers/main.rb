class Goliath::SimpleFrontend < Goliath::API
  # helpers do

  include Rack::Utils
  alias_method :h, :escape_html

  include Haml::Helpers

  # makes an anchor tag.
  def link_to text, path, options={}
    haml_tag(:a, h(text), options.reverse_merge(:href => h(path)))
  end

  def image_tag(src, alt=nil, options={})
    alt ||= File.basename(src).gsub(/.+$/, '')
    haml_tag :img, options.merge(:src => src, :alt => alt)
  end

  # end
end
