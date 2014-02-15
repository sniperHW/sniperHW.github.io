# Based on https://github.com/gummesson/jekyll-vimeo-plugin by Ellen Gummesson.
# 
# A plugin for embedding videos from Vimeo using a simple Liquid tag, ie: {% vimeo 12345678 %}.
# Based of the Youtube plugin from http://www.portwaypoint.co.uk/jekyll-youtube-liquid-template-tag-gist/
#
# Examples:
#   Input:
#     {% vimeo 1233 %}
#   Output:
#      <iframe width="500" height="281" src="http://player.vimeo.com/video/1233" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen/>
#
#   Input:
#     {% vimeo 1233 550 309 %}
#   Output:
#      <iframe width="550" height="309" src="http://player.vimeo.com/video/1233" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen/>


module Jekyll
  class Vimeo < Liquid::Tag
    @@default_width = 500
    @@default_height = 281
    
    VIDEO_ID_WITH_FRAME_SIZE = /(\d+)\s+(\d+)\s+(\d+)/i
    VIDEO_ID_ONLY = /(\d+)\s+/i

    def initialize(name, markup, tokens)
      super
      if markup =~ VIDEO_ID_WITH_FRAME_SIZE
         @id = $1
         @width = $2
         @height = $3
      elsif markup =~ VIDEO_ID_ONLY
         @id = $1
         @width = @@default_width
         @height = @@default_height
      end
    end

    def render(context)
      %(<iframe width="#{@width}" height="#{@height}" src="http://player.vimeo.com/video/#{@id}" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>)
    end
  end
end

Liquid::Template.register_tag('vimeo', Jekyll::Vimeo)
