# 1. Install the required gems
# In your terminal run: gem install octokit rest-client
require 'octokit'
require 'rest-client'
require 'json'

# 3. Retrieve commit messages from the last day
def get_last_day_commits(client, repo)
  since_time = Time.now - 86400 # 24 hours ago
  client.commits_since(repo, since_time)
end

def extract_commit_messages(commits)
  commits.map { |commit| commit[:commit][:message] }
end

# 4. Integrate with OpenAI API to generate human-readable summaries
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

# 5. Create the changelog file
def write_changelog(repo, summary)
  filename = "#{repo.gsub('/', '_')}_changelog.txt" # Replace the forward slash with an underscore

  File.open(filename, 'w') do |file|
    file.write("Changelog for #{repo}:\n\n")
    file.write(summary)
  end
end

# Main function
def main
  client = Octokit::Client.new(access_token: GITHUB_ACCESS_TOKEN)
  repo = 'latitude-dev/latitude' # Replace with your desired repository

  commits = get_last_day_commits(client, repo)
  commit_messages = extract_commit_messages(commits)
  summary = generate_summary(commit_messages)

  write_changelog(repo, summary)
  puts "Changelog generated for #{repo}."
end

main

