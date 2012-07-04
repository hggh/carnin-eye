class Muplugin < ActiveRecord::Base
  belongs_to :category
  belongs_to :host
  
  def filename
    File.join('plugin_data', host.name + '__' + plg_name + '.muconfig')
  end
  
  def graph_field_filename(field)
    "servers." + host.name.split(".").reverse.join(".") + "." + graphite_name.downcase + "." + field.downcase
  end
  
  def graph(period)
    munin_plg = Munin::Plugin.new(plg_name, IO.readlines(filename))
    graph_height = Configuration.graph_height
    # Add some height if more field are available
    if munin_plg.fields.count() > 5
      graph_height = graph_height.to_i + (munin_plg.fields.count * 3)
    end
    ggraph = GraphiteGraph.new(:none)
    ggraph.title plg_title
    ggraph.vtitle munin_plg.vlabel
    ggraph.from "-1#{period}"
    ggraph.width Configuration.graph_width
    ggraph.height graph_height
    ggraph.hide_legend false
    ggraph.ymax munin_plg.ymax if munin_plg.ymax
    munin_plg.fields.each do |k|
      foptions = munin_plg.get_field(k)
      ggraph.field ":#{k}", :data => graph_field_filename(k),
        :alias => foptions[:desc],
        :derivative => foptions[:derivative],
        :scale_to_seconds => foptions[:scale_to_seconds],
        :scale => foptions[:scale]
    end
    url = Configuration.graphite_url + ggraph.url
    
    return url
  end

end
