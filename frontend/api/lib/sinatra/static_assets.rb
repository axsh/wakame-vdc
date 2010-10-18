require 'sinatra/base'
require 'sinatra/url_for'

module Sinatra
  module StaticAssets
    module Helpers
      # In HTML <link> and <img> tags have no end tag.
      # In XHTML, on the contrary, these tags must be properly closed.
      #
      # We can choose the appropriate behaviour with +closed+ option:
      #
      #   image_tag "/images/foo.png", :alt => "Foo itself", :closed => true
      #
      # The default value of +closed+ option is +false+.
      #
      def image_tag(source, options = {})
        options[:src] = url_for(source)
        tag("img", options)
      end

      def stylesheet_link_tag(*sources)
        list, options = extract_options(sources)
        list.collect { |source| stylesheet_tag(source, options) }.join("\n")
      end

      def javascript_script_tag(*sources)
        list, options = extract_options(sources)
        list.collect { |source| javascript_tag(source, options) }.join("\n")
      end

      def link_to(desc, url, options = {})
        tag("a", options.merge(:href => url_for(url))) do
          desc
        end
      end

      private

      def tag(name, local_options = {})
        start_tag = "<#{name}#{tag_options(local_options) if local_options}"
        if block_given?
          content = yield
          "#{start_tag}>#{content}</#{name}>"
        else
          "#{start_tag}#{"/" if options.xhtml}>"
        end
      end

      def tag_options(options)
        unless options.empty?
          attrs = []
          attrs = options.map { |key, value| %(#{key}="#{Rack::Utils.escape_html(value)}") }
          " #{attrs.sort * ' '}" unless attrs.empty?
        end
      end

      def stylesheet_tag(source, options = {})
        tag("link", { :type => "text/css",
            :charset => "utf-8", :media => "screen", :rel => "stylesheet",
            :href => url_for(source) }.merge(options))
      end

      def javascript_tag(source, options = {})
        tag("script", { :type => "text/javascript", :charset => "utf-8",
            :src => url_for(source) }.merge(options)) do
            end
      end

      def extract_options(a)
        opts = a.last.is_a?(::Hash) ? a.pop : {}
        [a, opts]
      end

    end

    def self.registered(app)
      app.helpers StaticAssets::Helpers
      app.disable :xhtml
    end
  end

  register StaticAssets
end
