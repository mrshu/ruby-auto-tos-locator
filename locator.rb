require 'rubygems'
require 'bundler/setup'
require 'ruby-readability'

require 'open-uri'

def stringify_node(node, attribute)
  return "/%s[@%s='%s']" % [node.name, attribute, node.attr(attribute)]
end

def article_xpath(elem)
  # number of tags that we've included in the selector that didn't have either
  # a class or an id
  clean_tags = 0
  out = ''
  for _ in 1..3
    if elem.attr('class') =~ /privacy|policy|service/i
      out = stringify_node(elem, 'class') + out
      break
    end

    if elem.attr('id') =~ /privacy|policy|service/i
      out = stringify_node(elem, 'id') + out
      break
    end

    if not elem.attr('id').nil?
      out = stringify_node(elem, 'id') + out
    elsif not elem.attr('class').nil?
      out = stringify_node(elem, 'class') + out
    else
      clean_tags += 1
    end

    elem = elem.parent
  end

  if clean_tags == 3
    return Nokogiri::CSS.xpath_for elem.css_path
  else
    return out
  end

end



url = ARGV[0]

source = open(url).read
doc = Readability::Document.new(source)
content = doc.content

puts content
puts article_xpath(doc.best_candidate[:elem])

