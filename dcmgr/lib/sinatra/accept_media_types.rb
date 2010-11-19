module Rack
  class Request
    # The media types of the HTTP_ACCEPT header ordered according to their
    # "quality" (preference level), without any media type parameters.
    #
    # ===== Examples
    #
    #   env['HTTP_ACCEPT']  #=> 'application/xml;q=0.8,text/html,text/plain;q=0.9'
    #
    #   req = Rack::Request.new(env)
    #   req.accept_media_types          #=> ['text/html', 'text/plain', 'application/xml']
    #   req.accept_media_types.prefered #=>  'text/html'
    #
    # For more information, see:
    # * Acept header:   http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    # * Quality values: http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.9
    #
    # ===== Returns
    # AcceptMediaTypes:: ordered list of accept header's media types
    #
    def accept_media_types
       @accept_media_types ||= Rack::AcceptMediaTypes.new(@env['HTTP_ACCEPT'])
    end
  end

  # AcceptMediaTypes is intended for wrapping env['HTTP_ACCEPT'].
  #
  # It allows ordering of its values (accepted media types) according to their
  # "quality" (preference level).
  #
  # This wrapper is typically used to determine the request's prefered media
  # type (see example below).
  #
  # ===== Examples
  #
  #   env['HTTP_ACCEPT']  #=> 'application/xml;q=0.8,text/html,text/plain;q=0.9'
  #
  #   types = Rack::AcceptMediaTypes.new(env['HTTP_ACCEPT'])
  #   types               #=> ['text/html', 'text/plain', 'application/xml']
  #   types.prefered      #=>  'text/html'
  #
  # ===== Notes
  #
  # For simplicity, media type parameters are striped, as they are seldom used
  # in practice. Users who need them are excepted to parse the Accept header
  # manually.
  #
  # ===== References
  #
  # HTTP 1.1 Specs:
  # * http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
  # * http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.9
  #
  class AcceptMediaTypes < Array

    #--
    # NOTE
    # Reason for special handling of nil accept header:
    #
    # "If no Accept header field is present, then it is assumed that the client
    # accepts all media types."
    #
    def initialize(header)
      if header.nil?
        replace(['*/*'])
      else
        replace(order(header.gsub(/ /, '').split(/,/)))
      end
    end

    # The client's prefered media type.
    def prefered
      first
    end

    private

    # Order media types by quality values, remove invalid types, and return media ranges.
    #
    def order(types) #:nodoc:
      types.map {|type| AcceptMediaType.new(type) }.reverse.sort.reverse.select {|type| type.valid? }.map {|type| type.range }
    end

    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    #
    class AcceptMediaType #:nodoc:
      include Comparable

      # media-range = ( "*/*"
      #               | ( type "/" "*" )
      #               | ( type "/" subtype )
      #               ) *( ";" parameter )
      attr_accessor :range

      # qvalue = ( "0" [ "." 0*3DIGIT ] )
      #        | ( "1" [ "." 0*3("0") ] )
      attr_accessor :quality

      def initialize(type)
        self.range, *params = type.split(';')
        self.quality = extract_quality(params)
      end

      def <=>(type)
        self.quality <=> type.quality
      end

      # "A weight is normalized to a real number in the range 0 through 1,
      # where 0 is the minimum and 1 the maximum value. If a parameter has a
      # quality value of 0, then content with this parameter is `not
      # acceptable' for the client."
      #
      def valid?
        self.quality.between?(0.1, 1)
      end

      private
        # Extract value from 'q=FLOAT' parameter if present, otherwise assume 1
        #
        # "The default value is q=1."
        #
        def extract_quality(params)
          q = params.detect {|p| p.match(/q=\d\.?\d{0,3}/) }
          q ? q.split('=').last.to_f : 1.0
        end
    end
  end
end
