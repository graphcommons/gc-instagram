require 'instagram'
require 'curl'

Instagram.configure do |config|
  config.client_id = ENV["IG_CLIENT_ID"]
  config.client_secret = ENV["IG_CLIENT_SECRET"]
end

liker_hash = Hash.new # to avoid duplicates

# node signals are collected here
nodes_array = Array.new

#edge signals are collected here
edges_array = Array.new

client = Instagram.client(:access_token => ENV["IG_ACCESS_TOKEN"])
media_feed = client.user_recent_media


for media_item in media_feed
  image_hash = Hash.new

  # adding Image node
  nodes_array << {
    :action => "node_create",
    :name => media_item.id,
    :type => "Image",
    :description => media_item.caption.nil? ? "Untitled" : media_item.caption.text,
    :reference => media_item.link,
    :image => media_item.images.standard_resolution.url
  }

  media_item.likes.data.each do |liker|
    # skip if liker node is already added
    if liker_hash[liker.username].nil?
      nodes_array << {
        :action => "node_create",
        :name => liker.username,
        :type => "Liker",
        :image => liker.profile_picture
      }

      liker_hash[liker.username] = true
    end

    # Liker -[LIKES]->Image
    edges_array << {
      :action => "edge_create",
      :from_name => liker.username,
      :from_type => "Liker",
      :to_name => media_item.id,
      :to_type => "Image",
      :name => "LIKES"
    }
  end
end

# building the body of the request to generate the graph
# note the node and edge arrays are concatenated into the signals key
generate_graph = {
  :name => "Instagram Map",
  :status => 0,
  :subtitle => "Mapping my instagram likers",
  :signals => nodes_array + edges_array
}

# dont forget to set the API KEY in the header
c = Curl::Easy.http_post("http://graphcommons.com/api/v1/graphs", generate_graph.to_json) do |curl|
  curl.headers['Content-Type'] = 'application/json'
  curl.headers['Authentication'] = ENV["GC_API_KEY"]
end

# output the response, just print out the id
response_hash = JSON.parse(c.body_str, {:symbolize_names => true})
puts response_hash[:graph][:id]
