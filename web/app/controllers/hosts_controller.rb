class HostsController < ApplicationController
  protect_from_forgery :except => :munin_update
  def index
    @domains = Domain.sorted_with_hosts
    @hosts = Host.all
  end

  def munin_update
    json = JSON.parse(params[:json])
    json.keys.each do |host|
      hostname, domainname = host.to_s.split(/\./, 2)
      @domain = Domain.select_update(domainname)
      if !@host = @domain.hosts.find_by_name(host)
        @host = @domain.hosts.new
        @host.name = host
        @host.save
      end
      json[host].keys.each do |plugin|
        munin_plugin = Munin::Plugin.new(plugin, json[host][plugin]["config"])
        unless @category = Category.find_by_name(munin_plugin.category)
          @category = Category.new
          @category.name = munin_plugin.category
          @category.save
        end

        unless @muplugin = @host.muplugins.find_by_plg_name(plugin)
          @muplugin = @host.muplugins.new
          @muplugin.plg_name = plugin
        end
        @muplugin.category_id   = @category.id
        @muplugin.graphite_name = json[host][plugin]["name_clean"]
        @muplugin.plg_title     = munin_plugin.plg_title
        @muplugin.plg_info      = munin_plugin.plg_info
        @muplugin.save
        File.open(@muplugin.filename, 'w') do |f|
          f.puts json[host][plugin]["config"]
        end
        

      ## FIXME: Delete Old plugins from database
      end
    end
  end

  def show
    @host = Host.find(params[:id])
  end
end
