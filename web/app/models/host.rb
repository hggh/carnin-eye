class Host < ActiveRecord::Base
  belongs_to :domain
  has_many :muplugins, :dependent => :destroy
  has_many :categories, :through => :muplugins

  validates :name, :presence => true, :uniqueness => true


  def get_plugins_by_category_id(category_id)
    muplugins.where("category_id = ?", category_id).order("plg_title ASC")
  end

  def get_categories
    categories.group("name").order("name ASC")
  end
end
