#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'ruby-readability'

require 'open-uri'
require 'open_uri_redirections'

def stringify_node(node, attribute)
  return "/%s[@%s='%s']" % [node.name, attribute, node.attr(attribute)]
end

def article_xpath(elem)
  # number of tags that we've included in the selector that didn't have either
  # a class or an id
  clean_tags = 0
  out = ''
  for _ in 1..3
    if elem.attr('id') =~ /^contents?$/i
      out = stringify_node(elem, 'id')
      break
    end

    # if there is a class that explicitely as terms, privacy, policy or service
    # in it then it should be enough to locate our desired content on the page
    # by using this element
    if elem.attr('class') =~ /terms|privacy|policy|service|contents?/i
      out = stringify_node(elem, 'class') + out
      break
    end

    # the same logic as with class applies
    if elem.attr('id') =~ /terms|privacy|policy|service|contents?/i
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

    begin
      elem = elem.parent
    rescue NoMethodError
      elem = elem
    end
  end

  # if we ran into just clean tags rather return a direct XPath than our 3-way
  # approximation
  if clean_tags == 3
    begin
      return Nokogiri::CSS.xpath_for elem.css_path
    rescue Nokogiri::CSS::SyntaxError
      return "//div[@id='css-syntax-error']"
    end
  else
    return '/' + out
  end
end

def tosback_xml(url, xpath, content)
  sitename = URI(url).host.match(/[^\.]+\.\w+$/).to_s
  type = 'ToS'
  if content =~ /privacy/i and content =~ /policy|policies/i
    type = 'Privacy Policy'
  elsif content =~ /terms/i and content =~ /service|services/i
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

def xpath_contents_from_url(url)
  source = open(url, :allow_redirections => :all).read
  doc = Readability::Document.new(source)
  content = doc.content

  xpath = article_xpath(doc.best_candidate[:elem])

  return content, xpath
end

if __FILE__ == $0
  url = ARGV[0]
  content, xpath = xpath_contents_from_url(url)
  puts content
  puts "\n\n"
  puts tosback_xml(url, xpath, content)
end
