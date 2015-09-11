## GC API Demo

A program to generate a Graph Commons map from an Instagram account. It demonstrates how to use Graph Commons api to generate graphs programmatically.

#### Scope
This program simply queries my latest posts on Instagram and creates a map of people who liked my posts.

#### Obtaining Access Tokens
In order to use this program, you will first have to create an Instagram Application and obtain an access token for this application. https://instagram.com/developer/clients/manage/

You also need an API Key for Graph Commons. You can generate an API key in your profile at Graph Commons. https://graphcommons.com/me/edit

#### Components
- `init_access.rb` is used to obtain Instagram access token.
- `app.rb` is the actual program that queries Instagram and creates a graph on Graph Commons.

#### Build and Run

- Make sure you have `bundler` installed.
- Run `bundle install`
- Run `init_access.rb` with ENV variables for Instagram Client ID and Client Secret and retrieve your access token
```
IG_CLIENT_ID=<ig_client_id> IG_CLIENT_SECRET=<ig_client_secret> ruby init_access.rb
```
- Run `app.rb` with ENV variables for IG Client Id, IG Client Secret, IG Access Token and GC API key
```
IG_CLIENT_ID=<ig_client_id> IG_CLIENT_SECRET=<ig_client_secret> IG_ACCESS_TOKEN=<ig_access_token> GC_API_KEY=<gc_api_key> ruby app.rb
```
- If all works well, you should see the id of the generated graph in the output.

#### Sample Output
Here's the graph I generated with this program:
https://graphcommons.com/graphs/7c244715-6de4-45c5-a1dd-7959b1aee17d
