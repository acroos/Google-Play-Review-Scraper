require 'selenium-webdriver'

app_name = ARGV[0]
out_file = File.open(ARGV[1],'w+')
num_elem = 0

driver = Selenium::WebDriver.for :firefox
driver.navigate.to 'https://play.google.com/store/apps'

wait = Selenium::WebDriver::Wait.new(:timeout => 60)

puts "Entering search text"
wait.until { driver.find_element(:name, 'q') }
element = driver.find_element(:name, 'q')
element.send_keys app_name
element.submit

puts "Clicking on first card"
wait.until { driver.find_element(:partial_link_text, app_name) }
element = driver.find_element(:partial_link_text, app_name)
element.click

puts "Getting number of reviews"
wait.until { driver.find_element(:class_name, "reviews-num") }
elements = driver.find_elements(:class_name, "reviews-num")
num_revs = elements[0].text.gsub(',','').to_i

puts "Harvesting reviews..."
while num_elem < num_revs
	begin
		wait.until { driver.find_element(:class_name, "expand-next") }
		elements = driver.find_elements(:class_name, "expand-next")
		elements[1].click
	rescue
		wait.until { driver.find_element(:class_name, "expand-next") }
		elements = driver.find_elements(:class_name, "expand-next")
		elements[1].click
	end

	wait.until { driver.find_element(:class_name, "review-body") }
	elements = driver.find_elements(:class_name, "review-body")

	elements.each do |element|
		unless element.text.nil? or element.text.empty?
			out_file.write("#{element.text}\n")
			num_elem += 1
		end
	end
	puts "#{num_elem} harvested"
end

puts "Done.  #{num_elem} reviews written to #{ARGV[1]}"

driver.quit

#