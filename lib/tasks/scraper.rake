namespace :scraper do
  desc "fetch craigslist posts from 3taps"
  task scrape: :environment do
require 'open-uri'
require 'json'

#set API token and URL
auth_token = "4a3b24be2f3bfd59a97b9f039cebe910"
polling_url = "http://polling.3taps.com/poll"

# Specify request parameters
params = {
  auth_token: auth_token,
  anchor: 1648959468,
  source: "CRAIG",
  category_group: "RRRR",
  category: "RHFR",
  'location.city' => "USA-MIA-MIB",
  retvals: "location,external_url,heading,body,timestamp,price,images,annotations"
}

# Prepare API request
uri = URI.parse(polling_url)
uri.query = URI.encode_www_form(params)

# Submit request
result = JSON.parse(open(uri).read)

# Display results to screen
# puts result["postings"].first["images"].first["full"]
#puts  result["postings"].first["location"]["locality"]
#puts JSON.pretty_generate result["postings"].first["annotations"]

# store results in database
result["postings"].each do |posting|
# Create new Post
  @post = Post.new
  @post.heading = posting["heading"]
  @post.body = posting["body"]
  @post.price = posting["price"]
  @post.neighborhood = Location.find_by(code: posting["location"]["locality"]).try(:name)
  @post.external_url = posting["external_url"]
  @post.timestamp = posting["timestamp"]
  @post.bedrooms = posting["annotations"]["bedrooms"] if posting["annotations"]["bedrooms"].present?
  @post.bathrooms = posting["annotations"]["bathrooms"] if posting["annotations"]["bathrooms"].present?
  @post.sqft = posting["annotations"]["sqft"] if posting["annotations"]["sqft"].present?
  @post.cats = posting["annotations"]["cats"] if posting["annotations"]["cats"].present?
  @post.dogs = posting["annotations"]["dogs"] if posting["annotations"]["dogs"].present?
  @post.w_d_in_unit = posting["annotations"]["w_d_in_unit"] if posting["annotations"]["w_d_in_unit"].present?
  @post.street_parking = posting["annotations"]["street_parking"] if posting["annotations"]["street_parking"].present?

# Save Post
  @post.save

  # loop over images and save to image database
  	posting["images"].each do |image|
  	@image = Image.new
  	@image.url = image["full"]
  	@image.post_id = @post.id
  	@image.save
  end
 end
end

  desc "Destroy all posting data"
  task destroy_all_posts: :environment do
  	Post.destroy_all
  end

  desc "Save Neighborhood codes in a region"
  task scrape_neighborhoods: :environment do
require 'open-uri'
require 'json'

#set API token and URL
auth_token = "4a3b24be2f3bfd59a97b9f039cebe910"
location_url = "http://reference.3taps.com/locations"

# Specify request parameters
params = {
  auth_token: auth_token,
  level: "locality",
  city: "USA-MIA-MIB"
}

# Prepare API request
uri = URI.parse(location_url)
uri.query = URI.encode_www_form(params)

# Submit request
result = JSON.parse(open(uri).read)

# Display results to screen

# puts JSON.pretty_generate result

#Store results in database
result["locations"].each do |location|
	@location = Location.new
	@location.code = location["code"]
	@location.name = location["short_name"]
	@location.save
	end
  end
end
