#!/usr/bin/env ruby

require 'bundler/setup'

require 'nokogiri'
require './locator.rb'
require 'similar_text'

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

      contents = input.at_xpath(xpath)

      begin
        _, new_xpath = xpath_contents_from_url(url)
      rescue Exception => e
        puts "MISSED other problem (xpath_contents_from_url) (#{e}!) " + url
        problematic_urls.push(url)
        next
      end

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
        new_xpath_urls.push(url)
      elsif contents != new_contents and similarity < 95.0
        puts "FAIL " + url + " similarity: " + similarity.to_s
        puts "=========================="
        puts xpath, new_xpath, url
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
