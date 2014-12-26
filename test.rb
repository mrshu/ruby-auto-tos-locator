#!/usr/bin/env ruby

require 'nokogiri'
require './locator.rb'
require 'similar_text'

problematic_urls = Array.new

rules = Dir.glob(File.join("tosback2", "rules", "*.xml"))
rules.each { |x|
  doc = Nokogiri::XML(File.open(x)) do |config|
    config.strict.nonet
  end

  doc.remove_namespaces!

  doc.css('docname').each do |node|
    node.css('url').each do |n|
      url = n.attributes["name"]
      xpath = n.attributes["xpath"].to_s

      if xpath.length == 0
        # not really interested for now
        next
      end

      begin
        input = Nokogiri::HTML(open(url, :allow_redirections => :safe))
      rescue Exception => e
        puts "MISSED other problem (403?) (#{e}!) " + url
        problematic_urls.push(url)
        next
      end

      contents = input.at_xpath(xpath)

      _, new_xpath = xpath_contents_from_url(url)

      new_contents = input.at_xpath(new_xpath)

      begin
        c = contents.to_s
        nc = new_contents.to_s
      rescue ArgumentError
        puts "MISSED encoding problem " + url
        next
      end

      similarity = c.similar(nc)

      if c.length == 0 and nc.length != 0
        puts "NEW BETTER XPATH " + url + " " + new_xpath + " vs " + xpath
      elsif contents != new_contents and similarity < 95.0
        puts "FAIL " + url + " similarity: " + similarity.to_s
        puts "=========================="
        puts contents
        puts "----------------------\n\n"
        puts new_contents
        puts "----------------------\n\n"
        puts xpath, new_xpath, url
        puts "=========================="
      else
        puts "PASSED " + url + " similarity:" + similarity.to_s
      end
    end
  end
}