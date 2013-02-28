module ApplicationHelper
  def liquidize(content, arguments, filters = [])
    Liquid::Template.parse(content).render(arguments, :filters => filters)
  end
end
