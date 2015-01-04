#!/usr/bin/env ruby

require 'bundler/setup'

require 'nokogiri'
require './locator.rb'
require 'similar_text'
require 'sanitize'

require 'set'

# dice coefficient = bigram overlap * 2 / bigrams in a + bigrams in b
def dice_coefficient(a, b)
        a_bigrams = a.each_char.each_cons(2).to_set
        b_bigrams = b.each_char.each_cons(2).to_set

        overlap = (a_bigrams & b_bigrams).size

        total = a_bigrams.size + b_bigrams.size
        dice  = overlap * 2.0 / total

        dice
end

def format_newdata(newdata)
  newdata.gsub!(/\s{2,}/," ") # changes big gaps of space to a single space
  newdata.gsub!(/\.\s|;\s/,".\n") # adds new line char after all ". "'s
  newdata.gsub!(/\n\s/,"\n") # removes single spaces at the beginning of lines
  newdata.gsub!(/>\s*</,">\n<") # newline between tags
  newdata
end

def strip_tags(newdata)
  begin
    newdata = Sanitize.clean(newdata, :remove_contents => ["script", "style"], :elements => %w[ abbr b blockquote br cite code dd dfn dl dt em i li ol p q s small strike strong sub sup u ul ], :whitespace_elements => []) # strips non-style html tags and removes content between <script> and <style> tags
  rescue Encoding::CompatibilityError
    newdata.encode!("UTF-8", :undef => :replace)
    newdata = Sanitize.clean(newdata, :remove_contents => ["script", "style"], :elements => %w[ abbr b blockquote br cite code dd dfn dl dt em i li ol p q s small strike strong sub sup u ul ], :whitespace_elements => [])
  rescue ArgumentError
    newdata.encode!('ISO-8859-1', {:invalid => :replace, :undef => :replace})
    newdata.encode!('UTF-8', {:invalid => :replace, :undef => :replace})
    newdata = Sanitize.clean(newdata, :remove_contents => ["script", "style"], :elements => %w[ abbr b blockquote br cite code dd dfn dl dt em i li ol p q s small strike strong sub sup u ul ], :whitespace_elements => [])
  end
  newdata
end

problematic_urls = Array.new
passed_urls = Array.new
new_xpath_urls = Array.new
failed_urls = Array.new

rules = Dir.glob(File.join("tosback2", "rules", "*.xml"))
rules.each { |x|
  doc = Nokogiri::XML(File.open(x)) do |config|
    config.strict.nonet
  end

  # Just some 300 of them
  if rand(10) >= 6 and ARGV.length == 1 and ARGV[0] == 'travis'
    next
  end

  doc.css('docname').each do |node|
    node.css('url').each do |n|
      url = n.attributes["name"]
      xpath = n.attributes["xpath"].to_s

      # DuckDuckGo Policy is for some reason causing segfaults on Travis
      if url == "https://duckduckgo.com/privacy.html" and ARGV.length == 1 and ARGV[0] == 'travis'
        next
      end

      if xpath.length == 0
        # not really interested for now
        next
      end

      puts "Testing URL: #{url}"

      begin
        input = Nokogiri::HTML(open(url, :allow_redirections => :all))
      rescue Exception => e
        puts "MISSED other problem (nokogiri html parse) (#{e}!) " + url
        problematic_urls.push(url)
        next
      end

      contents = input.search(xpath)

      begin
        _, new_xpath = xpath_contents_from_url(url)
      rescue Exception => e
        puts "MISSED other problem (xpath_contents_from_url) (#{e}!) " + url
        problematic_urls.push(url)
        next
      end

      puts "XPath from locator: #{new_xpath}"
      new_contents = input.search(new_xpath)

      begin
        c = format_newdata(strip_tags(contents.to_s))
        nc = format_newdata(strip_tags(new_contents.to_s))
      rescue ArgumentError
        puts "MISSED encoding problem " + url
        next
      end

      # similarity = c.similar(nc)
      similarity = dice_coefficient(c, nc) * 100.0

      if c.length == 0 and nc.length != 0
        puts "NEW BETTER XPATH " + url + " " + new_xpath + " vs " + xpath
        new_xpath_urls.push(url)
      elsif (c != nc and similarity < 95.0) or (c.length == 0 and nc.length == 0)
        puts "FAIL " + url + " similarity: " + similarity.to_s
        puts "=========================="
        puts xpath, new_xpath, url, c.length, nc.length
        puts "=========================="
        failed_urls.push(url)
      else
        puts "PASSED " + url + " similarity:" + similarity.to_s
        passed_urls.push(url)
      end
    end
  end
}

passed_tests = passed_urls.length.to_f
missed_tests = problematic_urls.length.to_f
failed_tests = failed_urls.length.to_f
new_xpath_tests = new_xpath_urls.length.to_f

total_tests = passed_tests + missed_tests + failed_tests + new_xpath_tests

passed_tests_perc = (passed_tests/total_tests*100.0)
missed_tests_perc = (missed_tests/total_tests*100.0)
failed_tests_perc = (failed_tests/total_tests*100.0)
new_xpath_tests_perc = (new_xpath_tests/total_tests*100.0)

accuracy = (passed_tests + new_xpath_tests)/(passed_tests + new_xpath_tests + failed_tests)*100.0


puts "=================="
puts "     Summary      "
puts "=================="
puts "Passed tests:\t#{passed_tests}\t#{passed_tests_perc}"
puts "New XPaths:\t#{new_xpath_tests}\t#{new_xpath_tests_perc}"
puts "Missed tests:\t#{missed_tests}\t#{missed_tests_perc}"
puts "Failed tests:\t#{failed_tests}\t#{failed_tests_perc}"
puts "Total tests:\t#{total_tests}\t100.0"
puts "Accuracy:\t#{accuracy}"
