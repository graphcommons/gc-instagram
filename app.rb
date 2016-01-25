require 'instagram'
require 'curl'
require 'date'

# Using
# IG_CLIENT_ID= IG_CLIENT_SECRET= IG_ACCESS_TOKEN= GC_API_KEY= ruby app.rb

Instagram.configure do |config|
  config.client_id = ENV["IG_CLIENT_ID"]
  config.client_secret = ENV["IG_CLIENT_SECRET"]
end

@apikey = ENV["IG_ACCESS_TOKEN"]

# avoid duplicate users
person_hash = Hash.new

# node signals are collected here
nodes_array = Array.new
nodetypes_array = Array.new

# edge signals are collected here
edges_array = Array.new
edgetypes_array = Array.new

# media items are collected here
media_items = Array.new

# post frequency
post_times =  Array.new

# reactions per post, per follower
total_likes = 0
total_comments = 0
graph_description = "" # for metrics

# 5K rate limiting per hour per user https://www.instagram.com/developer/limits/
# Assumed: 3.33 posts per day per user:
# 3.33 posts per day * 30 day ~= 100 media items (api calls for post extended information)
# 300 / 20 recent media per call = 15 api calls for all post ids
num_media_items = 100
max_page = (num_media_items/20).to_i - 1

client = Instagram.client(:access_token => @apikey)

current_user = client.user
puts current_user.username
total_posts = current_user.counts["media"]
followings = current_user.counts["follows"]
followers = current_user.counts["followed_by"]
puts "#{total_posts} posts"
puts "#{followings} followings"
puts "#{followers} followers"
graph_description << "#{total_posts} posts <br>"
graph_description << "#{followings} followings <br>"
graph_description << "#{followers} followers <br>"
graph_description << "--- <br>"

puts "---"

for i in 0..max_page
    if i == 0
        recent_media = client.user_recent_media
        page_max_id = recent_media.pagination.next_max_id
    else
        recent_media = client.user_recent_media(:max_id => page_max_id) unless page_max_id.nil?
        page_max_id = recent_media.pagination.next_max_id
    end
    media_items = media_items + recent_media
    puts "#{media_items.size} posts"
end

media_items.each do |media_item|

    # create the "Photo" node
    nodes_array << {
        :action => "node_create",
        :name => media_item.id,
        :type => "Photo",
        :description => media_item.caption.nil? ? "Untitled" : media_item.caption.text,
        :image => media_item.images.standard_resolution.url,
        :reference => media_item.link,
        :properties => {
            :likes => media_item.likes["count"],
            :comments => media_item.comments["count"],
            :posted_at => media_item.created_time,
            :location_name => media_item.location ? media_item.location.name : nil,
            :location_lat => media_item.location ? media_item.location.latitude : nil,
            :location_lon => media_item.location ? media_item.location.longitude : nil,
            :location_id => media_item.location ? media_item.location.id : nil
          }
    }
    total_likes = total_likes + media_item.likes["count"].to_i
    total_comments = total_comments + media_item.comments["count"].to_i

    # media_item limited to 4 likes & comments,
    # so make extended call for each media
    media_likes = client.media_likes(media_item.id)
    media_comments = client.media_comments(media_item.id)

    # Turn likes to graph signals
    unless media_likes.nil?
        media_likes.each do |person| # media_item.likes.data.each do |person|
            # create the "Person" node, skip if already added
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

            # Person -[LIKED]-> Photo
            edges_array << {
              :action => "edge_create",
              :from_name => person.username,
              :from_type => "Person",
              :to_name => media_item.id,
              :to_type => "Photo",
              :name => "LIKED"
            }
        end
    end

    # Turn comments to graph signals
    unless media_comments.nil?
        media_comments.each do |comment| # media_item.comments.data.each do |comment|
            person = comment.from
            if person_hash[person.username].nil?
                puts "#{person.username} #{person.id} COMMENTED"
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

            # Person -[COMMENTED]-> Photo
            edges_array << {
              :action => "edge_create",
              :from_name => person.username,
              :from_type => "Person",
              :to_name => media_item.id,
              :to_type => "Photo",
              :name => "COMMENTED",
              :properties => {
                  :text => comment.text,
                  :id => comment.id,
                  :posted_at => comment.created_time
              }
            }
        end
    end

    post_times << Time.at(media_item.created_time.to_i).to_datetime
end

puts "---"

# Calcualte posts per day
daily_posts = post_times.group_by {|t| t.strftime("%Y-%m-%d")}
posts_per_day = []
daily_posts.each {|k,v| posts_per_day << v.size }
avg_post_per_day = (posts_per_day.inject{ |sum, el| sum + el }.to_f / posts_per_day.size).round(2)
puts "#{avg_post_per_day} avg posts per day"
graph_description << "#{avg_post_per_day} avg posts per day <br>"

graph_description << "--- <br>"

# Calcualte avg reactions per post
total_media_items = media_items.size.to_f
avg_likes_per_post = (total_likes / total_media_items).round(2)
avg_comments_per_post = (total_comments / total_media_items).round(2)
puts "#{avg_likes_per_post} avg likes per post"
puts "#{avg_comments_per_post} avg comments per post"
graph_description << "#{avg_likes_per_post} avg likes per post <br>"
graph_description << "#{avg_comments_per_post} avg comments per post <br>"

graph_description << "--- <br>"

# Calcualte raw reactions per follower (non follower reactions not separated)
avg_likes_per_follower = (total_likes / followers.to_f).round(2)
avg_comments_per_follower = (total_comments / followers.to_f).round(2)
puts "#{avg_likes_per_follower} avg likes per follower"
puts "#{avg_comments_per_follower} avg comments per follower"
graph_description << "#{avg_likes_per_follower} avg likes per follower <br>"
graph_description << "#{avg_comments_per_follower} avg comments per follower <br>"

puts "---"

# Set color for nodetypes and eddgetypes
nodetypes_array << {
      :action => "nodetype_create",
      :name => "Person",
      :color => "#3473C6"
    }
nodetypes_array << {
      :action => "nodetype_create",
      :name => "Photo",
      :color => "#C5A7A3",
      :hide_name => true,
      :image_as_icon => true
    }
edgetypes_array << {
      :action => "edgetype_create",
      :name => "LIKED",
      :color => "#6296DC"
    }
edgetypes_array << {
      :action => "edgetype_create",
      :name => "COMMENTED",
      :color => "#FFC400"
    }

puts "Creating the graph..."
host = "http://localhost:3000"
# building the body of the request to generate the graph
# note the node and edge arrays are concatenated into the signals key
generate_graph = {
  :name => "Instagram graph for #{current_user.username}",
  :status => 0,
  :subtitle => "Network of photos and people who liked and commented",
  :description => graph_description,
  :signals => nodes_array + edges_array + nodetypes_array + edgetypes_array
}

# dont forget to set the API KEY in the header"
c = Curl::Easy.http_post("#{host}/api/v1/graphs", generate_graph.to_json) do |curl|
  curl.headers['Content-Type'] = 'application/json'
  curl.headers['Authentication'] = ENV["GC_API_KEY"]
end

# output the response, just print out the id
response_hash = JSON.parse(c.body_str, {:symbolize_names => true})
puts "#{host}/graphs/#{response_hash[:graph][:id]}"
