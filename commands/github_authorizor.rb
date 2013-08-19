class GitHubAuthorizor < Struct.new(:username)
  def github
    @github ||= Ghee.basic_auth(*ENV['GITHUB'].split('@'))
  end

  def execute
    if username.empty?
      speak("Please provide a GitHub username: `haml authorize @HamlTheHamster`")
    else
      github.orgs(ENV['GITHUB_ORGANIZATION']).teams(ENV['GITHUB_TEAM_ID']).members.add(
        username.gsub('@', '')
      ) or raise "Could not add member #{username} to #{ENV['GITHUB_TEAM_ID']} in #{ENV['GITHUB_ORGANIZATION']}"

      speak("Added #{username} to ##{ENV['GITHUB_TEAM_ID']} in #{ENV['GITHUB_ORGANIZATION']}")
      speak("https://github.com/organizations/#{ENV['GITHUB_ORGANIZATION']}/teams/#{ENV['GITHUB_TEAM_ID']}")
    end
  rescue => e
    speak(e.message)
  end
end
