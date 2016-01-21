require 'instagram'
require 'curl'

# Using
# IG_CLIENT_ID= IG_CLIENT_SECRET= IG_ACCESS_TOKEN= GC_API_KEY= ruby app.rb

Instagram.configure do |config|
  config.client_id = ENV["IG_CLIENT_ID"]
  config.client_secret = ENV["IG_CLIENT_SECRET"]
end

@apikey = ENV["IG_ACCESS_TOKEN"]

# def get_user_id(client, username)
#     results = client.user_search(username, :count=>1)
#     # puts results
#     results.each do |user|
#         if username == user.username
#             return user.id
#         else
#             return nil
#         end
#     end
# end

# avoid duplicate users
person_hash = Hash.new

# node signals are collected here
nodes_array = Array.new

# edge signals are collected here
edges_array = Array.new

# media items are collected here
media_items = Array.new

client = Instagram.client(:access_token => @apikey)

num_media_items = 200
max_page = (num_media_items/20).to_i - 1

current_user = client.user

for i in 0..max_page
    if i == 0
        recent_media = client.user_recent_media
        page_max_id = recent_media.pagination.next_max_id
    else
        recent_media = client.user_recent_media(:max_id => page_max_id) unless page_max_id.nil?
        page_max_id = recent_media.pagination.next_max_id
    end
    media_items = media_items + recent_media
    puts media_items.size
end

media_items.each do |media_item|

    image_hash = Hash.new

    # create the "Image" node
    nodes_array << {
        :action => "node_create",
        :name => media_item.id,
        :type => "Image",
        :description => media_item.caption.nil? ? "Untitled" : media_item.caption.text,
        :image => media_item.images.standard_resolution.url,
        :reference => media_item.link
    }

    puts media_item.link
    # puts "COMMENTS:"
    # puts media_item.comments
    # puts "LIKES:"
    # puts media_item.likes

    # Turn comments to graph signals
    media_item.comments.data.each do |comment|
        person = comment.from
        if person_hash[person.username].nil?
            puts "#{person.username} #{person.id} COMMENTED"

            nodes_array << {
                :action => "node_create",
                :name => person.username,
                :type => "Person",
                :description => person.id,
                :image => person.profile_picture,
                :reference => "https://instagram.com/#{person.username}",
                :properties => {
                    :comments_count => media_item.comments.data.count,
                    :likes_count => media_item.likes.data.count,
                    :created_at => media_item.created_time
                  }
            }
            person_hash[person.username] = true
        end

        # Person -[COMMENTED]-> Image
        edges_array << {
          :action => "edge_create",
          :from_name => person.username,
          :from_type => "Person",
          :to_name => media_item.id,
          :to_type => "Image",
          :name => "COMMENTED"
        }
    end

    # Turn likes to graph signals
    media_item.likes.data.each do |person|
        # create the "Person" node, skip if person node is already added
        if person_hash[person.username].nil?
            puts "#{person.username} #{person.id} LIKED"

            nodes_array << {
                :action => "node_create",
                :name => person.username,
                :type => "Person",
                :description => person.id,
                :image => person.profile_picture,
                :reference => "https://instagram.com/#{person.username}"
            }
            person_hash[person.username] = true
        end

        # Person -[LIKED]-> Image
        edges_array << {
          :action => "edge_create",
          :from_name => person.username,
          :from_type => "Person",
          :to_name => media_item.id,
          :to_type => "Image",
          :name => "LIKED"
        }
    end

    # break
 end

puts "Creating the graph..."

# building the body of the request to generate the graph
# note the node and edge arrays are concatenated into the signals key
generate_graph = {
  :name => "Instagram graph for #{current_user.username}",
  :status => 0,
  :subtitle => "Network of photos and people who liked and commented",
  :signals => nodes_array + edges_array
}

# dont forget to set the API KEY in the header"
host = "http://localhost:3000"
c = Curl::Easy.http_post("#{host}/api/v1/graphs", generate_graph.to_json) do |curl|
  curl.headers['Content-Type'] = 'application/json'
  curl.headers['Authentication'] = ENV["GC_API_KEY"]
end

# output the response, just print out the id
response_hash = JSON.parse(c.body_str, {:symbolize_names => true})
puts "#{host}/graphs/#{response_hash[:graph][:id]}"
