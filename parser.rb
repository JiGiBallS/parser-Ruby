require "curb"
require "nokogiri"
require "csv"
require 'pry'
require 'pry-nav'

puts "Getting start parser"

PRODUCT_LIST_URL = "https://www.petsonic.com/snacks-huesos-para-perros/"

CSV.open("products.csv", "w") do |csv|
  csv << ["Name", "Price", "Image URL"]

  page = 1
  product_urls = []
puts "Getting product links"
  loop do
    page_url = PRODUCT_LIST_URL
    #getting page
    page == 1 ? response = Curl.get(page_url) : response = Curl.get(page_url, { "p" => page })
    puts response.url
    document = Nokogiri::HTML(response.body_str)
    #gettink links from page
    urls = document.css("ul#product_list li a.product-name").map { |node| node.attr("href") }
    break if urls.empty?
    product_urls.push(*urls)
    page += 1
  end
  
puts "Record in csv"
  mutex = Mutex.new

  threads = product_urls.map do |product_url|
    Thread.new do
    	#getting getting product page
      response = Curl.get(product_url)
      document = Nokogiri::HTML(response.body_str)
      name = document.css("h1").text
      image_url = document.css("#image-block span img").attr("src").text

      version = 1
      loop do
      	#getting the right information
        version_node = document.css(".attribute_list li:nth-child(#{version})")
        break if version_node.empty?

        weight = version_node.css("span:first-child").text
        price = version_node.css(".price_comb").text
        #record the necessary information in a csv file
        mutex.synchronize do
          csv << ["#{name} - #{weight}", price, image_url]
          puts "#{name} - #{weight}"
          puts price
          puts image_url
          puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        end

        version += 1
      end
    end
  end

  threads.each(&:join)
end
puts "done"