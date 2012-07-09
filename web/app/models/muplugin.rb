class Muplugin < ActiveRecord::Base
  belongs_to :category
  belongs_to :host

  def filename
    File.join('plugin_data', host.name + '__' + plg_name + '.muconfig')
  end
  
  def graph_field_filename(field)
    "servers." + host.name.split(".").reverse.join(".") + "." + graphite_name.downcase + "." + field.downcase
  end
  
  def graph(time_start = "-30h", time_end = "now")
    munin_plg = Munin::Plugin.new(plg_name, IO.readlines(filename))
    graph_height = Configuration.graph_height
    # Add some height if more field are available
    if munin_plg.fields.count() > 5
      graph_height = graph_height.to_i + (munin_plg.fields.count * 3)
    end
    ggraph = GraphiteGraph.new(:none)
    ggraph.title plg_title
    ggraph.vtitle munin_plg.vlabel
    ggraph.from time_start.to_s
    ggraph.until time_end.to_s
    ggraph.width Configuration.graph_width
    ggraph.height graph_height
    ggraph.hide_legend false
    ggraph.ymax munin_plg.ymax if munin_plg.ymax
    ggraph.ymin munin_plg.ymin if munin_plg.ymin
    ggraph.yunit_system munin_plg.yunit_system if munin_plg.yunit_system
    # Color Stuff
    ggraph.major_grid_line_color 'efadad'
    ggraph.minor_grid_line_color 'd0d0d0'
    ggraph.background_color 'f3f3f3'
    ggraph.foreground_color 'black'
    # Custom format for daily graph
    if time_start.to_s == Configuration.graph_time_day
      ggraph.xformat '%a %H:%M'
    end
    ggraph.fontsize '9'
    graph_id = 0
    munin_plg.fields.each do |k|
      color = Configuration.graph_single_color
      if munin_plg.fields.count > 1
        color = get_color(graph_id)
      end
      foptions = munin_plg.get_field(k)
      ggraph.field ":#{k}", :data => graph_field_filename(k),
        :alias => foptions[:desc],
        :derivative => foptions[:derivative],
        :scale_to_seconds => foptions[:scale_to_seconds],
        :scale => foptions[:scale],
        :color => color
      graph_id += 1
    end
    url = Configuration.graphite_url + ggraph.url

    return url
  end

  def get_color(id)
    if id > Configuration.graph_colors.split(/ /).count
      id = id - (Configuration.graph_colors.split(/ /).count - 1 )
    end
    Configuration.graph_colors.split(/ /)[id]
  end
end
