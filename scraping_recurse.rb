require 'nokogiri'
require 'open-uri'
require 'awesome_print'
require 'json'
require 'date'

# sleep(4.minutes) example of sleep

def scrapeWhisky
  page = nil
  results = []
  results = parse_page(page, results)
  puts results

  results.each do |result|
    if result[:age] == 0
      result[:age] = Date.today.strftime("%Y").to_i - result[:year]
    end
  end
  puts '*' * 10
  puts '*' * 10

  puts results.to_json
  # {results}.to_json
end

def parse_page(href, results)

  next_url = href || "?0&rating=0&price=0&category_id=1"
  results = results || []

  url = open("http://whiskyadvocate.com/ratings-reviews/#{next_url}").read
  page = Nokogiri::HTML(url)

  page.css('div[style="vertical-align:top"]').each do |el|
    result = {
      rating: el.css('div[style="float:left; width:50px;"] h2').text.to_i,
      name: /^[^,]*/.match(el.css('.review h2').text).to_s,
      brand: el.css('.review a')[0].text,
      wa_brand_id: /(?<=\=)[\d*]{1,}/.match(el.css('.review a')[0]['href']).to_s,
      age: /\s[\d]{2}\s/.match(el.css('.review h2').text).to_s.strip.to_i,
      price: /(?<=\$)[\d*^,]{1,}/.match(el.css('.review h2').text).to_s.gsub(/,/, "").to_i,
      year: /\s[\d*]{4}/.match(el.css('.review h2').text).to_s.strip.to_i
    }
    results.push(result)
  end

  if page.css('.post a').last.text == "Next 10 Reviews"
    puts "-" * 10
    puts page.css('.post a').last["href"]
    puts "-" * 10
    parse_page(page.css('.post a').last["href"], results)
  end

  return results
end

scrapeWhisky