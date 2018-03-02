#! /usr/bin/env ruby
# coding: utf-8

require 'pp'
require 'selenium-webdriver'
require 'nokogiri'

JUSTWATCH_COUNTRY = 'jp'

case JUSTWATCH_COUNTRY
when 'jp'
  url = 'https://www.justwatch.com/jp'
  title_str = 'JustWatch　動画配信　映画　TV番組　検索エンジン'
when 'us'
  url = 'https://www.justwatch.com/us'
  title_str = 'JustWatch - Streaming Search Engine for movies and tv shows'
else
  puts "[ERROR] #{JUSTWATCH_COUNTRY} is not unspported!"
  exit
end

driver = Selenium::WebDriver.for :chrome

# refer http://katsulog.tech/i-do-not-recommend-using-sleep-when-waiting-for-elements/
wait = Selenium::WebDriver::Wait.new(:timeout => 10) 

# When first title seems to be 'JustWatch'
# After title of page is as same as titel_str, we are ready to get the video's title
wait.until do
  driver.get url
  break if driver.title == title_str
end

# after moved video list pages
title_cnt = 1

loop do
  html = driver.page_source

  # parse page by nokogiri
  html_doc = Nokogiri::HTML(html)
  xpath = "//*[@id=\"content\"]/div/div[2]/div[position()>=#{title_cnt}]/title-card/track-title-control/div/div[1]/div/div/a/img"
  elements = html_doc.xpath(xpath)

  title_cnt_1 = elements.size

  if elements.size > 0 then
    puts "***** #{elements.size}"
    elements.each do |nodeset|
      puts "[#{title_cnt}] #{nodeset.attribute('alt')}"
      title_cnt += 1
    end
  else
    puts "[ERROR] no element xpath:#{xpath}"
    exit
  end

  # refer https://stackoverflow.com/questions/7327858/how-to-scroll-with-selenium
  # find the last element for scrolling next page
  xpath = "//*[@id=\"content\"]/div/div[2]/div[position()=#{title_cnt-1}]/title-card/track-title-control/div/div[1]/div/div/a/img"
  elements = driver.find_element(:xpath,xpath)

  # scroll next page
  elements.location_once_scrolled_into_view

  sleep 2

end

driver.quit
