require 'nokogiri'
require 'open-uri'
require 'awesome_print'
require 'sinatra'
require 'json'
require 'date'

# .meaning
# category_id = 1
# brand_id = 69 (ardbeg)
# sleep(4.minutes) example of sleep


get "/:term" do
  term = params[:term]

  url = open("http://whiskyadvocate.com/ratings-reviews/?0&rating=0&price=5000-99999&category_id=1").read
  page = Nokogiri::HTML(url)

  results = page.css('div[style="vertical-align:top"]').map do |el|
      {
        rating: el.css('div[style="float:left; width:50px;"] h2').text.to_i,
        name: /^[^,]*/.match(el.css('.review h2').text).to_s,
        brand: el.css('.review a')[0].text,
        age: /\s[\d]{2}\s/.match(el.css('.review h2').text).to_s.strip.to_i,
        price: /(?<=\$)[\d*^,]{1,}/.match(el.css('.review h2').text).to_s.gsub(/,/, "").to_i,
        year: /\s[\d*]{4}/.match(el.css('.review h2').text).to_s.strip.to_i
      }
  end

  next_page = page.css('.post a').last['href']
  puts next_page

  next_url = open("http://whiskyadvocate.com/ratings-reviews/#{next_page}").read
  page = Nokogiri::HTML(next_url)

  page.css('div[style="vertical-align:top"]').each do |el|
    result = {
      rating: el.css('div[style="float:left; width:50px;"] h2').text.to_i,
      name: /^[^,]*/.match(el.css('.review h2').text).to_s,
      brand: el.css('.review a')[0].text,
      age: /\s[\d]{2}\s/.match(el.css('.review h2').text).to_s.strip.to_i,
      price: /(?<=\$)[\d*^,]{1,}/.match(el.css('.review h2').text).to_s.gsub(/,/, "").to_i,
      year: /\s[\d*]{4}/.match(el.css('.review h2').text).to_s.strip.to_i
    }
    results.push(result)
  end

  results.each do |result|
    if result[:age] == 0
      result[:age] = Date.today.strftime("%Y").to_i - result[:year]
    end
  end

  # this gives the first 20 results for highest rated scotch
  # could loop through all scotch this way (questionable ethics)
  # each.results loop to save these to the db
  # have to run this within rails with a timer
  # clean up by grabbing year, and doing math on it to get age for
  # missing ages

  # http://whiskyadvocate.com/ratings-reviews/?brand_id=69&rating=0&price=0&category_id=0&issue_id=0&reviewer=0
  {results: results}.to_json
end