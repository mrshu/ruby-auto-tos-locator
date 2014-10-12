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
    # if there is a class that explicitely as terms, privacy, policy or service
    # in it then it should be enough to locate our desired content on the page
    # by using this element
    if elem.attr('class') =~ /terms|privacy|policy|service/i
      out = stringify_node(elem, 'class') + out
      break
    end

    # the same logic as with class applies
    if elem.attr('id') =~ /terms|privacy|policy|service/i
      out = stringify_node(elem, 'id') + out
      break
    end

    if not elem.attr('id').nil?
      out = stringify_node(elem, 'id') + out
    elsif not elem.attr('class').nil?
      out = stringify_node(elem, 'class') + out
    else
      clean_tags += 1
      out = '/' + elem.name + out
    end

    elem = elem.parent
  end

  # if we ran into just clean tags rather return a direct XPath than our 3-way
  # approximation
  if clean_tags == 3
    return Nokogiri::CSS.xpath_for elem.css_path
  else
    return '/' + out
  end
end

def tosback_xml(url, xpath, content)
  sitename = URI(url).host.match(/[^\.]+\.\w+$/).to_s
  type = 'ToS'
  if content =~ /privacy/i and content =~ /policy/i
    type = 'Privacy Policy'
  elsif content =~ /terms/i and content =~ /service/i
    type = 'Terms of Service'

  end

  return <<-XML
<sitename name="#{sitename}">
  <docname name="#{type}">
    <url name="#{url}" xpath="#{xpath}">
     <norecurse name="arbitrary"/>
    </url>
  </docname>
</sitename>
XML
end


url = ARGV[0]

source = open(url).read
doc = Readability::Document.new(source)
content = doc.content
xpath = article_xpath(doc.best_candidate[:elem])

puts content
puts xpath
puts "\n\n"
puts tosback_xml(url, xpath, content)

