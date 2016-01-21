This program generates a network map on Graph Commons based on your recent Instagram photos and their likes and comments. It aggregates people, photos, likes, comments from my last 200 posts and turns actions into connections, demonstrating how to use [Graph Commons API](https://graphcommons.com/dev) to generate graphs programmatically.

#### Components
- `init_access.rb` is a Sinatra server to obtain your Instagram access token.
- `app.rb` is the actual program that queries Instagram and creates a graph on Graph Commons.

#### Obtain Access Tokens
In order to use this program, you will need two access tokens:

1. Create an Instagram Application and obtain its access token: https://instagram.com/developer/clients/manage/

2. Get your API key for Graph Commons from your profile: https://graphcommons.com/me/edit

#### Setup
- `git clone git@github.com:graphcommons/gc-instagram.git`
- `cd gc-instagram`
- `bundle install` (Make sure you have `bundler` installed)

#### Using
1. Run `init_access.rb` with ENV variables for Instagram Client ID and Client Secret
```
IG_CLIENT_ID=<ig_client_id> IG_CLIENT_SECRET=<ig_client_secret> ruby init_access.rb
```
2. Open browser `localhost:4567` and click on the link to retrieve your Instagram access token

3. Run `app.rb` with four ENV variables:
    - Instagram Client Id
    - Instagram Client Secret
    - Instagram Access Token
    - Graph Commons API key
```
IG_CLIENT_ID=<ig_client_id> IG_CLIENT_SECRET=<ig_client_secret> IG_ACCESS_TOKEN=<ig_access_token> GC_API_KEY=<gc_api_key> ruby app.rb
```
4. If all works well, you should see the URL of the generated graph, open it in the browser and enjoy your Instagram graph.

#### Sample Output
Here's the graph generated with this program:
https://graphcommons.com/graphs/7c244715-6de4-45c5-a1dd-7959b1aee17d

#### Where to go from here
Learn more about the Graph Commons API documentation https://graphcommons.github.io/api-v1
