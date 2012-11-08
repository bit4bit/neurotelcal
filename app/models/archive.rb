class Archive < ActiveRecord::Base
  attr_accessible :version, :processing, :campaign_id, :name
  
  belongs_to :campaign
 # before_save :verify_need_calls
  

  def verify_need_calls
    return true if Call.where("created_at >= ? AND created_at <= ?", from_at, to_at).count > 0 and PlivoCall.where("created_at >= ? AND created_at <= ?", from_at, to_at).count > 0
    errors.add(:from_at, 'No hay llamadas para archivar')
    return false
  end

  def path()
    Rails.root.join('archive','%s_%d.gz' % [created_at.to_s(:number), self.id])
  end

  
  def self.transaction_security
    self.disable_security
    yield

    #@todo COMO ACTIVAR DE NUEVO??
    #model_attrs.each do |m,v|
      #m.accessible_attributes = v.dup
   # end
  end
  
  #::block:: block with element_xml:string type:simbol[:campaign, :call]
  def auto_parse(&block)
    #@todo buscar otra forma, esto es algo tosco
    self.class.parse_archive(path(), &block)
  end

  private  
  def self.disable_security
    model_attrs = {Campaign => nil, Group => nil, Message => nil, MessageCalendar => nil, Client => nil, Entity => nil, Call => nil, PlivoCall => nil}
    model_attrs.each do |m,v|
      model_attrs[m] = m.column_names.dup
      asc = m.reflect_on_all_associations.map { |assoc| assoc.name.to_s}
      asc.each{|c| m.accessible_attributes << c}
      m.column_names.each{|c| m.accessible_attributes << c}
    end
  end

  def self.parse_archive(file, &block)
    Zlib::GzipReader.open(file) do |gz|
      self.get_element_xml(gz, "<campaign>", "</campaign>") do |element|
        block.call(element, :campaign)
      end
      #gz.rewind
      self.get_element_xml(gz, "<call>","</call>", true) do |element|
        block.call(element, :call)
      end
    end
  end
  

  def self.get_element_xml(stream, tag_start, tag_end, multi = false)
    element = ""
    stack = ""
    cstack = 0
    in_element = false
    
    while not stream.eof()
      c = stream.readchar
      
      if c == tag_start[cstack] or c == tag_end[cstack]
        cstack += 1
        stack << c
      else
        cstack = 0
        stack.clear
      end
      
      if stack == tag_start
        in_element = true
        element << stack
        stack.clear; cstack = 0
      elsif in_element
        element << c
      end
      
      if stack == tag_end
        yield element 
        break unless multi

        in_element = false
        element = ""
        stack.clear; cstack = 0
      end
    end
    return element
  end
    

end
