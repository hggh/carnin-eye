class Dashboard::Entry
  attr_reader :name, :info, :graphs
  def initialize(dir)
    @dir    = dir
    @description = ""
    @graphs = Array.new
    Dir.entries(dir).each do |d|
      if d =~ /\.graph$/
        @graphs << Dashboard::Graph.new(File.join(@dir, d))
      end
    end

    yaml = YAML.load_file(File.join(dir, 'dash.yml'))
    @name = yaml[:name].to_s
    @info = yaml[:description].to_s if yaml[:description]
  end

  def graphs?
    if @graphs.count > 0
      true
    else
      false
    end
  end
end
