class SearchController < ApplicationController
  def query
    @hosts = Host.where('name LIKE ?', '%' + params[:search_box] + '%')
  end
end
