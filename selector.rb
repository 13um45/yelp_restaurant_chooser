require 'httparty'

SEARCH_DEFAULTS = {term: 'food', location: nil, latitude: nil, longitude: nil, radius: nil, categories: nil,
                   locale: nil, limit: nil, offset: nil, sort_by: nil, price: nil, open_now: nil, open_at: nil,
                   attributes: nil}

class Business
  attr_accessor :name, :display_phone, :distance, :price, :image_url, :url, :is_closed, :coordinates, :id, :phone,
                :review_count, :categories, :location, :rating

  def initialize(biz_attr)
    @name = biz_attr['name']
    @display_phone = biz_attr['display_phone']
    @distance = biz_attr['distance']
    @price = biz_attr['price']
    @image_url = biz_attr['image_url']
    @url = biz_attr['url']
    @is_closed = biz_attr['is_closed']
    @coordinates = biz_attr['coordinates']
    @id = biz_attr['id']
    @phone = biz_attr['phone']
    @review_count = biz_attr['review_count']
    @categories = biz_attr['categories']
    @location = biz_attr['location']
    @rating = biz_attr['rating']
  end

  def distance
    sprintf('%.2f', (@distance / 1609.344)) unless @distance.nil?
  end

  def categories
    arr = @categories.map { |c| c['title'] }
    arr.join(", ")
  end

  def self.gimme_a_restaurant(biz_objects)
    biz_objects.sample
  end
end

class Search
  attr_accessor :term, :location, :latitude, :longitude, :radius, :categories, :locale, :limit,
                :offset, :sort_by, :price, :open_now, :open_at, :attributes

  def initialize(req_attr)
    req_attr = SEARCH_DEFAULTS.merge(req_attr)
    @term = req_attr[:term]
    @location = req_attr[:location]
    @latitude = req_attr[:latitude]
    @longitude = req_attr[:longitude]
    @radius = req_attr[:radius]
    @categories = req_attr[:categories]
    @locale = req_attr[:locale]
    @limit = req_attr[:limit]
    @offset = req_attr[:offset]
    @sort_by = req_attr[:sort_by]
    @price = req_attr[:price]
    @open_now = req_attr[:open_now]
    @open_at = req_attr[:open_at]
    @attributes = req_attr[:attributes]
    @request = build_request(req_attr)
  end

  def businesses
    businesses_arr = HTTParty.get(@request, headers: {'Authorization' => "Bearer #{ENV['YELP_ACCESS_TOKEN']}"}).parsed_response['businesses']
    business_objects = []
    businesses_arr.each do |business|
      business_objects << Business.new(business)
    end
    business_objects
  end

  private
  def build_request(req_attr)
    'https://api.yelp.com/v3/businesses/search?' + append_search_parameters(req_attr)
  end

  def append_search_parameters(params)
    string = ''
    params.each do |key, value|
      string += key.to_s + '=' + "#{value}" + '&' unless value.nil?
    end
    string = string.gsub(' ', '+')
    string[-1] = ''
    string
  end
end

request_hash = {location: ENV['MY_LOCATION'], term: 'food', radius: 900, open_now: true, price: '1,2', limit: 50}

search = Search.new(request_hash)
rest = Business.gimme_a_restaurant(search.businesses)

attachments = [
    fallback: "Yelp Restaurant Chooser: selection for today: #{rest.name}",
    color: '#36a64f',
    pretext: "We will be eating at #{rest.name} today!",
    author_name: 'Yelp Restaurant Chooser',
    author_link: 'http://www.christiansamuel.net/',
    author_icon: 'https://s3-media3.fl.yelpcdn.com/assets/srv0/styleguide/b62d62e8722a/assets/img/brand_guidelines/yelp_fullcolor_outline@2x.png',
    title: "#{rest.name}",
    title_link: "#{rest.url}",
    text: "Category: #{rest.categories} \nRating: #{rest.rating} out of 5 stars \nPrice Range: #{rest.price}\nDistance: #{rest.distance} miles away",
    image_url: "#{rest.image_url}",
    footer: 'Christian made this',
    footer_icon: ENV['SLACK_AVATAR']
]

slack_message_hash = {username: 'yelp_restaurant_chooser', icon_emoji: ':yelp:', attachments: attachments}.to_json

HTTParty.post(ENV['SLACK_WEBHOOK_URL'], body: slack_message_hash)

puts "We will be eating at #{rest.name} today!"
puts "#{rest.name} is #{rest.distance} miles away."
puts "#{rest.name} has a Yelp rating of #{rest.rating}"
puts "#{rest.categories}"