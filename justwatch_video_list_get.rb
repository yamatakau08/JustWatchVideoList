#! /usr/bin/env ruby
# coding: utf-8

require 'pp'
require 'selenium-webdriver'
require 'nokogiri'

JUSTWATCH_COUNTRY = 'us'
USE_HEADLESS      = false

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

if USE_HEADLESS
  caps = Selenium::WebDriver::Remote::Capabilities.chrome(
    chrome_options: {
      args: %w[headless disable-gpu no-sandbox]
    }
  )
  driver = Selenium::WebDriver.for :chrome, desired_capabilities: caps 
else
  driver = Selenium::WebDriver.for :chrome
end

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

  # find_elements the video titles by xpath
  xpath = "//*[@id=\"content\"]/div/div[2]/div[position()>=#{title_cnt}]/title-card/track-title-control/div/div[1]/div/div/a/img"
  elements = driver.find_elements(:xpath,xpath) # refer https://groups.google.com/forum/#!topic/seleniumjp/QAUOtMd672k

  # check if elements exist
  if elements.size > 0 then
    puts "***** #{elements.size}" if false # for debug
    elements.each do |nodeset|
      puts "[#{title_cnt}] #{nodeset.attribute('alt')}"
      title_cnt += 1
    end
  else
    puts "[INFO] no more element xpath:#{xpath}"
    exit
  end

  # refer https://stackoverflow.com/questions/7327858/how-to-scroll-with-selenium
  # check if the last element exsits for scrolling next page
  xpath = "//*[@id=\"content\"]/div/div[2]/div[position()=#{title_cnt-1}]/title-card/track-title-control/div/div[1]/div/div/a/img"
  elements = driver.find_element(:xpath,xpath)

  # scroll next page
  elements.location_once_scrolled_into_view

  # wait until the first element is appear after the above scroll the page
  begin
    wait.until do
      xpath = "//*[@id=\"content\"]/div/div[2]/div[position()=#{title_cnt}]/title-card/track-title-control/div/div[1]/div/div/a/img"
      element = driver.find_element(:xpath,xpath)
      break if element.displayed?
    end
  rescue Selenium::WebDriver::Error::TimeOutError => error
    puts "[INFO] seems to be no more title!"
    puts "[ERROR] #{error}"
    break
  end

end

driver.quit
