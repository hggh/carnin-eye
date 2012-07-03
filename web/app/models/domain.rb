class Domain < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true

  has_many :hosts, :dependent => :destroy

  def self.sorted_with_hosts
    domains = Array.new
    Domain.order("name ASC").each do |d|
      domains << d if d.hosts.count > 0
    end
    domains
  end

  def self.select_update(domain_name)
    unless d= Domain.find_by_name(domain_name)
      d = Domain.new
      d.name = domain_name
      d.save
    end
    d
  end
end
