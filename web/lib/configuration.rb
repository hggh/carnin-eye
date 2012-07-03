class Configuration
	@settings = YAML::load_file('config/mdash-web.yml')[Rails.env]

	def self.method_missing(key)
		if @settings[key.to_s]
			@settings[key.to_s]
		else
			raise "Could not find key #{key.to_s} in ENV #{Rails.env}"
		end
	end
end
