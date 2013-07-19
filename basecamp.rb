require 'httparty'
require 'json'

class Basecamp
  class << self
    def client
      @client ||= self.new
    end

    def mark_as_completed(matching)
      client.assigned.first.tap do |todolist|
        todolist['assigned_todos'].select do |task|
          puts "Comparing #{task['content']}"
          task['content'] =~ matching
        end.each do |task|
          puts task.inspect
          puts "Marking #{task['name']} as completed", "\n" * 3
          puts task['url']
          puts "\n"
          Basecamp.client.mark_as_completed(task['url'])
        end
      end
    end
  end

  attr_accessor :username, :password, :account_endpoint

  def initialize username=nil, password=nil, account_endpoint=nil, app=nil
    @username = username || ENV['BASECAMP_CREDENTIALS'].to_s.split(':').first
    @password = password || ENV['BASECAMP_CREDENTIALS'].to_s.split(':').last
    @account_endpoint = account_endpoint || ENV['BASECAMP_ACCOUNT_ENDPOINT']
    @app = app || ENV['BASECAMP_USER_AGENT']

    [@username, @password, @account_endpoint, @app].any? do |v|
      raise "CHECK BASECAMP CONFIGURATION" if v.nil?
    end
  end

  def headers
    {
      "Content-Type" => 'application/json',
      "User-Agent" => @app
    }
  end

  def basic_auth

    {
      :username => @username,
      :password => @password
    }
  end

  def params
    {
      :basic_auth => basic_auth,
      :headers => headers
    }
  end

  def handle response
    if response.code == 200
      JSON.parse(response.body)
    else
      puts response.inspect
      nil
    end
  end

  def assigned
    response = HTTParty.get me['assigned_todos']['url'], params
    handle(response)
  end

  def mark_as_completed task_url
    response = HTTParty.put task_url, params.merge(
      body: { completed: true }.to_json)
    handle(response)
  end

  def me
    response = HTTParty.get "#{@account_endpoint}/people/me.json", params
    handle(response)
  end

  def projects
    response = HTTParty.get "#{@account_endpoint}/projects.json", params
    handle response
  end

  def project id
    response = HTTParty.get "#{@account_endpoint}/projects/#{id}.json", params
    handle response
  end

  def todolists project_id
    response = HTTParty.get "#{@account_endpoint}/projects/#{project_id}/todolists.json", params
    handle response
  end

  def todolist project_id, todolist_id
    response = HTTParty.get "#{@account_endpoint}/projects/#{project_id}/todolists/#{todolist_id}.json", params
    handle response
  end

  def todos project_id, todo_id
    response = HTTParty.get "#{@account_endpoint}/projects/#{project_id}/todos/#{todo_id}.json", params
    handle response
  end
end
