class CreatePing
  include Server

  def execute
    apps.each do |app|
      `curl https://#{app.name}.herokuapp.com/`
    end
  end
end
