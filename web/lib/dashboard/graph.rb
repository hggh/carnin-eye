class Dashboard::Graph
  attr_reader :graph_title, :filename
  def initialize(name)
    @filename = name
    File.read(name).each do |l|
      if l =~ /^title\s+"(.*)"/
        @graph_title = $1.to_s
      end
    end
    unless @graph_title
      raise "Dashboard #{name} title not found"
    end
  end

  def graph!
    ggraph = GraphiteGraph.new(@filename)
    ggraph.width Configuration.graph_width
    ggraph.height Configuration.graph_height
    ggraph.fontsize Configuration.graph_fontsize
    # Color Stuff
    ggraph.major_grid_line_color Configuration.graph_major_grid_line_color
    ggraph.minor_grid_line_color Configuration.graph_minor_grid_line_color
    ggraph.background_color Configuration.graph_background_color
    ggraph.foreground_color Configuration.graph_foreground_color

    Configuration.graphite_url + ggraph.url
  end
end
