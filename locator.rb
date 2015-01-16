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
  i = 0
  while i < 3

    # no terms or services have ever fit into a span or a p
    if ['span', 'p'].include? elem.name and out == ''
      if elem.attr('id').nil? and elem.attr('class').nil?
        elem = elem.parent
        next
      end
    end

    # if we are in a table and it is such a table that it only holds our text
    # we just traverse upwards
    if ['tr', 'td', 'tbody'].include? elem.name
      if elem.parent.elements.length == 1 and out == ''
        elem = elem.parent
        next
      end
    end

    if elem.attr('id') =~ /^contents?$/i
      out = stringify_node(elem, 'id')
      break
    end

    # if there is a class that explicitely as terms, privacy, policy or service
    # in it then it should be enough to locate our desired content on the page
    # by using this element
    if elem.attr('class') =~ /terms|privacy|policy|service/i
      out = stringify_node(elem, 'class') + out
      break
    end

    # the same logic as with class applies
    if elem.attr('id') =~ /terms|privacy|policy|service|/i
      out = stringify_node(elem, 'id') + out
      break
    end

    if not elem.attr('id').nil?
      out = stringify_node(elem, 'id') + out
    elsif not elem.attr('class').nil?
      out = stringify_node(elem, 'class') + out
    else
      clean_tags += 1
      full_xpath = Nokogiri::CSS.xpath_for(elem.css_path)[0].to_s
      out = '/' + full_xpath.split('/').last + out
    end

    begin
      elem = elem.parent
    rescue NoMethodError
      elem = elem
    end

    i += 1
  end

  # if we ran into just clean tags rather return a direct XPath than our 3-way
  # approximation
  if clean_tags == 3
    # if we get the top element directly, let's just return the whole HTML file
    # (not even body)
    if elem.css_path.empty?
      return '//html'
    else
      return Nokogiri::CSS.xpath_for(elem.css_path)[0].to_s
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
