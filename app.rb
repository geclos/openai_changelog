require 'sinatra'
require 'octokit'
require 'rest-client'
require 'json'

# 2. Set up the GitHub API access
GITHUB_ACCESS_TOKEN = ENV['GITHUB_ACCESS_TOKEN']
OPENAI_API_KEY = ENV['OPENAI_API_KEY']

def get_last_day_commits(client, repo)
  since_time = Time.now - 86400 # 24 hours ago
  client.commits_since(repo, since_time)
end

def extract_commit_messages(commits)
  commits.map { |commit| commit[:commit][:message] }
end

def generate_summary(commit_messages)
  prompt = "Please provide a simplified summary of the following commit messages, suitable for non-technical readers:\n\n"
  prompt += commit_messages.map.with_index { |msg, i| "#{i + 1}. #{msg}" }.join("\n")
  prompt += "\n\nSummarize in a non-technical manner:"

  headers = { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{OPENAI_API_KEY}" }

  response = RestClient.post(
    'https://api.openai.com/v1/completions',
    {   'model' => 'text-davinci-003', 'prompt' => prompt, 'max_tokens' => 100, 'n' => 1, 'stop' => nil }.to_json,
    headers
  )

  summary = JSON.parse(response)['choices'][0]['text']
  summary.strip
end

client = Octokit::Client.new(access_token: GITHUB_ACCESS_TOKEN)

get '/changelog/:user/:repo' do
  user = params['user']
  repo = params['repo']
  full_repo = "#{user}/#{repo}"

  commits = get_last_day_commits(client, full_repo)
  commit_messages = extract_commit_messages(commits)
  summary = generate_summary(commit_messages)

  # Return the changelog as an HTML response
  content_type 'text/html'
  <<-HTML
    <html>
      <head>
        <title>Changelog for #{full_repo}</title>
      </head>
      <body>
        <h1>Changelog for #{full_repo}</h1>
        <p>#{summary}</p>
      </body>
    </html>
  HTML
end

get '/health' do
  content_type :json
  { status: 'OK' }.to_json
end

Sinatra::Application.run! if __FILE__ == $0
