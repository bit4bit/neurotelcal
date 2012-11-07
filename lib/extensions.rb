#gracias a:http://eigenjoy.com/2008/08/11/activerecord-from_xml-and-from_json-part-2/
module ActiveRecord
  class Base
 
    def self.from_hash( hash )
      h = hash.dup
      h.each do |key,value|
        #print "key(%s) value(%s)\n" % [key, value.to_s]
        case value.class.to_s
        when 'Array'
          h[key].map! { |e| reflect_on_association(
             key.to_sym ).klass.from_hash e }
        when /\AHash(WithIndifferentAccess)?\Z/
          h[key] = reflect_on_association(
             key.to_sym ).klass.from_hash value
        end
      end
      new h
    end
 
    def self.from_json( json )
      from_hash safe_json_decode( json )
    end
 
    # The xml has a surrounding class tag (e.g. ship-to),
    # but the hash has no counterpart (e.g. 'ship_to' => {} )
    def self.from_xml( xml )
      from_hash begin
        Hash.from_xml(xml)[to_s.demodulize.underscore]
      rescue ; {} end
    end
 
  end # class Base
end # module ActiveRecord
 
### Global functions ###
 
# JSON.decode, or return {} if anything goes wrong.
def safe_json_decode( json )
  return {} if !json
  begin
    ActiveSupport::JSON.decode json
  rescue ; {} end
end
