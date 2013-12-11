
# @author Plivo
module PlivoHelper
  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'cgi'
  require 'rubygems'
  require 'builder'
  require 'openssl'
  require 'base64'


  # Plivo REST Helpers
  class Rest

    #@param [String, String] Your Plivo SID/ID and Auth Token
    #@return [Object] Rest object
    def initialize(url, id, token)
      @id = id
      @token = token
      @url = url
    end

    #sends a request and gets a response from the Plivo REST API
    #
    #@param [String, String, Hash]
    #path, the URL (relative to the endpoint URL, after the /v1
    #method, the HTTP method to use, defaults to POST
    #vars, for POST or PUT, a dict of data to send
    #
    #@return Plivo response XML
    #@raises [ArgumentError] Invalid path parameter
    #@raises [NotImplementedError] Method given is not implemented
    def request(path, method=nil, vars={})
      if !path || path.length < 1
          raise ArgumentError, 'Invalid path parameter'
        end
        if method && !['GET', 'POST'].include?(method)
          raise NotImplementedError, 'HTTP %s not implemented' % method
        end

        if path[0, 1] == '/'
          uri = @url + path
        else
          uri = @url + '/' + path
      end

      return fetch(uri, vars, method)
    end

    # REST Reload Plivo Config Helper
    def reload_config(call_params)
      path = '/v0.1/ReloadConfig/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Reload Plivo Cache Config Helper
    def reload_cache_config(call_params)
      path = '/v0.1/ReloadCacheConfig/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Call Helper
    def call(call_params)
      path = '/v0.1/Call/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Bulk Call Helper
    def bulk_call(call_params)
      path = '/v0.1/BulkCall/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Group Call Helper
    def group_call(call_params)
      path = '/v0.1/GroupCall/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Transfer Live Call Helper
    def transfer_call(call_params)
      path = '/v0.1/TransferCall/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Hangup All Live Calls Helper
    def hangup_all_calls()
      path = '/v0.1/HangupAllCalls/'
      method = 'POST'
      return request(path, method)
    end

    # REST Hangup Live Call Helper
    def hangup_call(call_params)
      path = '/v0.1/HangupCall/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Schedule Hangup Helper
    def schedule_hangup(call_params)
      path = '/v0.1/ScheduleHangup/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Cancel a Scheduled Hangup Helper
    def cancel_scheduled_hangup(call_params)
      path = '/v0.1/CancelScheduledHangup/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST RecordStart helper
    def record_start(call_params)
      path = '/v0.1/RecordStart/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST RecordStop
    def record_stop(call_params)
      path = '/v0.1/RecordStop/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Play something on a Call Helper
    def play(call_params)
      path = '/v0.1/Play/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST PlayStop on a Call Helper
    def play_stop(call_params)
      path = '/v0.1/PlayStop/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Schedule Play Helper
    def schedule_play(call_params)
      path = '/v0.1/SchedulePlay/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Cancel a Scheduled Play Helper
    def cancel_scheduled_play(call_params)
      path = '/v0.1/CancelScheduledPlay/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Add soundtouch audio effects to a Call Helper
    def sound_touch(call_params)
      path = '/v0.1/SoundTouch/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Remove soundtouch audio effects on a Call Helper
    def sound_touch_stop(call_params)
      path = '/v0.1/SoundTouchStop/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Send digits to a Call Helper
    def send_digits(call_params)
      path = '/v0.1/SendDigits/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Conference Mute helper
    def conference_mute(call_params)
      path = '/v0.1/ConferenceMute/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Conference Unmute helper
    def conference_unmute(call_params)
      path = '/v0.1/ConferenceUnmute/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Conference Kick helper
    def conference_kick(call_params)
      path = '/v0.1/ConferenceKick/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Conference Hangup helper
    def conference_hangup(call_params)
      path = '/v0.1/ConferenceHangup/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Conference Deaf helper
    def conference_deaf(call_params)
      path = '/v0.1/ConferenceDeaf/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Conference Undeaf helper
    def conference_undeaf(call_params)
      path = '/v0.1/ConferenceUndeaf/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Conference RecordStart helper
    def conference_record_start(call_params)
      path = '/v0.1/ConferenceRecordStart/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Conference RecordStop
    def conference_record_stop(call_params)
      path = '/v0.1/ConferenceRecordStop/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Conference Play helper
    def conference_play(call_params)
      path = '/v0.1/ConferencePlay/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Conference Speak helper
    def conference_speak(call_params)
      path = '/v0.1/ConferenceSpeak/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Conference List Helper
    def conference_list(call_params)
      path = '/v0.1/ConferenceList/'
      method = 'POST'
      return request(path, method, call_params)
    end

    # REST Conference List Members Helper
    def conference_list_members(call_params)
      path = '/v0.1/ConferenceListMembers/'
      method = 'POST'
      return request(path, method, call_params)
    end


    #encode the parameters into a URL friendly string
    #
    #@param [Hash] URL key / values
    #@return [String] Encoded URL
    protected
    def urlencode(params)
      params.to_a.collect! \
        { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
    end

    # Create the uri for the REST call
    #
    #@param [String, Hash] Base URL and URL parameters
    #@return [String] URI for the REST call
    def build_get_uri(uri, params)
      if params && params.length > 0
        if uri.include?('?')
          if uri[-1, 1] != '&'
            uri += '&'
          end
            uri += urlencode(params)
          else
            uri += '?' + urlencode(params)
        end
      end
      return uri
    end

    # Returns a http request for the given url and parameters
    #
    #@param [String, Hash, String] Base URL, URL parameters, optional METHOD
    #@return [String] URI for the REST call
    def fetch(url, params, method=nil)
      if method && method == 'GET'
        url = build_get_uri(url, params)
      end
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      #http.use_ssl = true

      if method && method == 'GET'
        req = Net::HTTP::Get.new(uri.request_uri)
      elsif method && method == 'DELETE'
        req = Net::HTTP::Delete.new(uri.request_uri)
      elsif method && method == 'PUT'
        req = Net::HTTP::Put.new(uri.request_uri)
        req.set_form_data(params)
      else
        req = Net::HTTP::Post.new(uri.request_uri)
        req.set_form_data(params)
      end
      req.basic_auth(@id, @token)
      req.read_timeout = 5
      return http.request(req)
    end
  end

  # RESTXML Response Helpers
  module Element
    module ClassMethods
      @attributes = []
      @allowed_element = []
      attr_accessor :attributes

      def allowed_element(*element)
        return @allowed_element if element == []
        @allowed_element = [] if @allowed_element.nil?
        element.each do |element_element|
          cleaned_element_element = element_element.to_s.slice(0,1).capitalize + element_element.to_s.slice(1..-1)
          @allowed_element << cleaned_element_element
        end
        @allowed_element = @allowed_element.uniq
      end

      def attributes(*attrs)
        return @attributes if attrs == []
        @attributes = [] if @attributes.nil?
        @attributes = (@attributes + attrs).uniq
        attr_accessor(*@attributes)
        @attributes
      end
    end

    def attributes
      self.class.attributes
    end

    #test if a given element element is allowed to be nested
      #
      #@param [Object] Element to be appended
      #@return [true, false]
    def allowed?(element_element)
      self.class.allowed_element.nil? ? false : self.class.allowed_element.include?(element_element.class.name.split('::')[1])
    end

    #initialize a plivo response object
      #
      #@param [String, Hash] Body of the element, and a hash of the attributes
      #@return [Object] Plivo element object
      #
      #@raises [ArgumentError] Invalid Argument
    def initialize(body = nil, params = {})
      @children = []
      if body.class == String
        @body = body
      else
        @body = nil
        params = body || {}
      end
      params.each do |k,v|
        if !self.class.attributes.nil? && self.class.attributes.include?(k)
          send(k.to_s+"=",v)
        else
          raise ArgumentError, "Attribute Not Supported"
        end
      end
    end

    #set an attribute key / value
      #no error checking
      #
      #@param [Hash] Hash of options
      #@return void
    def set(params = {})
      params.each do |k,v|
        self.class.attributes k.to_s
        send(k.to_s+"=",v)
      end
    end

    #output valid Plivo markup
      #
      #@param [Hash] Hash of options
      #@return [String] Plivo Markup (in XML)
    def respond(opts = {})
      opts[:builder]  ||= Builder::XmlMarkup.new(:indent => opts[:indent])
      b = opts[:builder]
      attrs = {}
      attributes.each {|a| attrs[a] = send(a) unless send(a).nil? } unless attributes.nil?

      if @children and @body.nil?
        b.__send__(self.class.to_s.split(/::/)[-1], attrs) do
          @children.each {|e|e.respond( opts.merge(:skip_instruct => true) )}
        end
      elsif @body and @children == []
        b.__send__(self.class.to_s.split(/::/)[-1], @body, attrs)
      else
        raise ArgumentError, "Cannot have children and a body at the same time"
      end
    end

    #output valid Plivo markup encoded for inclusion in a URL
      #
      #@param []
      #@return [String] URL encoded Plivo Markup (XML)
    def asURL()
      CGI::escape(self.respond)
    end

    def append(element_element)
      if(allowed?(element_element))
        @children << element_element
        @children[-1]
      else
        raise ArgumentError, "Element Not Supported"
      end
    end

    # Element Convenience Methods
    def addSpeak(string_to_speak = nil, opts = {})
      append PlivoHelper::Speak.new(string_to_speak, opts)
    end

    def addPlay(file_to_play = nil, opts = {})
      append PlivoHelper::Play.new(file_to_play, opts)
    end

    def addGetDigits(opts = {})
      append PlivoHelper::GetDigits.new(opts)
    end

    def addGetSpeech(opts = {})
      append PlivoHelper::GetSpeech.new(opts)
    end

    def addRecord(opts = {})
      append PlivoHelper::Record.new(opts)
    end

    def addDial(number = nil, opts = {})
      append PlivoHelper::Dial.new(number, opts)
    end

    def addRedirect(url = nil, opts = {})
      append PlivoHelper::Redirect.new(url, opts)
    end

    def addSIPTransfer(url = nil, opts = {})
      append PlivoHelper::SIPTransfer.new(url, opts)
    end

    def addWait(opts = {})
      append PlivoHelper::Wait.new(opts)
    end

    def addHangup(opts = {})
      append PlivoHelper::Hangup.new(opts)
    end

    def addNumber(number, opts = {})
      append PlivoHelper::Number.new(number, opts)
    end

    def addConference(room, opts = {})
      append PlivoHelper::Conference.new(room, opts)
    end

    def addPreAnswer(opts = {})
      append PlivoHelper::PreAnswer.new(opts)
    end

  end

  class Speak
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    attributes :voice, :language, :loop, :engine, :type, :method
  end

  class Play
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    attributes :loop
  end

  class GetDigits
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    attributes :action, :method, :timeout, :finishOnKey, :numDigits, :retries, :playBeep, :validDigits, :invalidDigitsSound
    allowed_element :play, :speak, :wait
  end

  class GetSpeech
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    attributes :action, :method, :timeout, :playBeep, :engine, :grammar, :grammarPath
    allowed_element :play, :speak, :wait
  end

  class Record
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    attributes :action, :method, :timeout, :finishOnKey, :maxLength, :playBeep, :fileFormat, :fileName, :filePath, :bothLegs, :record
  end

  class Dial
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    attributes :action, :method, :timeout, :hangupOnStar, :timeLimit, :callerId, :callerName, :confirmSound, :confirmKey, :dialMusic, :redirect, :callbackUrl, :callbackMethod, :digitsMatch
    allowed_element :number
  end

  class Redirect
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
  end

  class SIPTransfer
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    attributes :method
  end

  class Wait
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    attributes :length
  end

  class Hangup
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    attributes :reason, :schedule
  end

  class Number
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    attributes :sendDigits, :sendOnPreanswer, :gateways, :gatewayCodecs, :gatewayTimeouts, :gatewayRetries, :extraDialString
  end

  class Conference
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    attributes :muted, :enterSound, :exitSound, :startConferenceOnEnter, :endConferenceOnExit, :waitSound, :timeLimit, :hangupOnStar, :recordFilePath, :recordFileFormat, :recordFileName, :action, :method, :callbackUrl, :callbackMethod, :digitsMatch, :stayAlone, :floorEvent
  end

  class PreAnswer
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    allowed_element :Speak, :Play, :GetDigits, :Wait, :GetSpeech, :SIPTransfer, :Redirect
  end

  class Response
    extend PlivoHelper::Element::ClassMethods
    include PlivoHelper::Element
    allowed_element :Speak, :Play, :GetDigits, :Record, :Dial, :Redirect, :Wait, :Hangup, :PreAnswer, :Conference, :GetSpeech, :SIPTransfer
  end

  # Plivo Utility function and Request Validation class
  class Utils

    #initialize a plivo utils abject
    #
    #@param [String, String] Your Plivo SID/ID and Auth Token
    #@return [Object] Utils object
    def initialize(id, token)
      @id = id
      @token = token
    end

    def validateRequest(signature, url, params = {})
      sorted_post_params = params.sort
      data = url
      sorted_post_params.each do |pkey|
        data = data + pkey[0]+pkey[1]
      end
      digest = OpenSSL::Digest::Digest.new('sha1')
      expected = Base64.encode64(OpenSSL::HMAC.digest(digest, @token, data)).strip
      return expected == signature
    end
  end

end
