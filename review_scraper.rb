require 'selenium-webdriver'

app_name = ARGV[0]
out_file = File.open(ARGV[1],'w+')
num_elem = 0

out_file.write('reviewer name, number of stars, review')

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

if ARGV[2].nil? or ARGV[2] > 400
	num_revs = 400
else
	num_revs = ARGV[2].to_i
end

initial = 1
i,j=0,0
while num_elem < num_revs
	begin
		wait.until { driver.find_element(:class_name, "expand-next") }
		next_button = driver.find_elements(:class_name, "expand-next")
		driver.action.move_to(next_button[1]).perform
		next_button[1].click
	rescue
		wait.until { driver.find_element(:class_name, "expand-next") }
		next_button = driver.find_elements(:class_name, "expand-next")
		driver.action.move_to(next_button[1]).perform
		next_button[1].click
	end

	if initial == 1
		puts "Getting most recent reviews"
		sleep(3)
		filter_button = driver.find_elements(:class_name, "dropdown-menu")
		filter_button[0].click

		wait.until { driver.find_elements(:xpath, "//div[@class='dropdown-menu-children']/div[@class='dropdown-child']")}
		newest_button = driver.find_elements(:xpath, "//div[@class='dropdown-menu-children']/div[@class='dropdown-child']")[0]
		newest_button.click
		initial = 0
		puts "Harvesting reviews..."
	end

	sleep(2)

	wait.until { driver.find_elements(:xpath, "//div[@class='single-review']/div[@class='review-body']").count > 1 }
	reviews = driver.find_elements(:xpath, "//div[@class='single-review']/div[@class='review-body']")
	review_names = driver.find_elements(:xpath, "//span[@class='author-name']/a ")
	review_stars = driver.find_elements(:xpath, "//div[@class='review-info-star-rating']/div/div[@class='current-rating']")

	reviews.each do |review|
		unless review.text.nil? or review.text.empty?
			num_stars = review_stars[i].size['width'] / 13
			reviewer = review_names[j].text
			while reviewer.nil? or reviewer.empty?
				j+=1
				reviewer = review_names[j].text unless review_names[j].nil?
			end
			text = review.text.gsub(',', ';')
			out_file.write("#{reviewer},#{num_stars},#{text}\n")
			j+=1
			i+=1
			num_elem += 1
		end
	end
	puts "#{num_elem} harvested"
end

puts "Done.  #{num_elem} reviews written to #{ARGV[1]}"
out_file.close
driver.quit

#