class Munin
  class Plugin
    SCALE_TO_SECONDS = [ 'nfs_client', 'nginx_request', 'forks', 'interrupts', 'fw_packets' ]
    attr_reader :plg_title, :plg_info, :category, :vlabel, :fields, :name, :ymax
    def initialize(name,config)
      @name     = name
      @config   = config
      @fields   = Array.new
      @plg_info = ""
      @category = "other"
      @vlabel   = ""
      @ymax     = nil

      parse_config
    end
    
    def get_field(field)
      options = { :desc => "", :derivative => false, :scale_to_seconds => nil, :scale => nil }
      if @name =~ /^ip_/
        options[:scale] = '0.125'
      end
      if @name =~ /^if_.*/ and @name !~ /_err_/
        options[:derivative] = true
        if field == "down"
          options[:scale] = '-0.125'
        end
        if field == "up"
          options[:scale] = '0.125'
        end 
      end

      if @name == "swap" and field == "swap_in"
        options[:scale] = '-1'
      end

      options[:scale_to_seconds] = '1' if SCALE_TO_SECONDS.include?(@name)
      @config.each do |line|
        line.strip!
        next unless line =~ /^#{field}.*/
        if line =~ /^#{field}\.label (.*)/
          options[:desc] = $1
          next
        end
        if line =~ /^#{field}\.type DERIVE/
          options[:derivative] = true
          next
        end
      end
      options
    end
    
    def parse_config
      @config.each do |line|
        line.strip!
        if line =~ /^(.*)\.label/
          @fields << $1
          next
        end
        val = line.to_s.split(/ /, 2)
        if val[0].to_s == "graph_title"
          @plg_title = val[1]
          next
        end
        if val[0].to_s == "graph_category"
          @category = val[1]
          next
        end
        if val[0].to_s == "graph_info"
          @plg_info = val[1]
          next
        end
        if val[0].to_s == "graph_vlabel"
          @vlabel = val[1].to_s.gsub(/\$\{graph_period\}/, 'second')
          next
        end
        if val[0].to_s == "graph_args" and val[1].to_s =~ /--upper-limit (\d+)/
         # seems on Graphite upper-limit will hide some lines, so + 10 :-/
          @ymax = ($1.to_i + 10).to_s
        end
      end
      @fields.uniq!
    end
  end
end
