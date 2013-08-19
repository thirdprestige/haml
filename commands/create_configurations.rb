class CreateConfigurations
  def template_config_keys
    @template_config_keys ||= ENV['TEMPLATE_CONFIG_KEYS'].to_s.split(',').reject do |key|
    ENV[key].nil? || ENV[key].empty?
    end
  end

  def execute
    apps.each do |app|
      template_config_keys.reject do |key|
        # Hey! This is already configured
        app.config.keys.include?(key)
      end.each do |key|
        app.configure(key, ENV[key])
      end
    end
  end
end
