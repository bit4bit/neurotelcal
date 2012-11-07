require 'zlib'

campaign = ""
def get_element_xml(stream, tag_start, tag_end)
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
      in_element = false
      yield element
      element = ""
      stack.clear; cstack = 0
    end
  end
  return false
end

Zlib::GzipReader.open('ppp_2012-11-06 21:11:25 -0500.gz') do |gz|
  get_element_xml(gz, "<call\">","</call>") do |element|
    campaign += element
  end
  

end

print campaign
