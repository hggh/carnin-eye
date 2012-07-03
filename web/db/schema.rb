# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120626211603) do

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "categories", ["name"], :name => "index_categories_on_name"

  create_table "domains", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "domains", ["name"], :name => "index_domains_on_name"

  create_table "hosts", :force => true do |t|
    t.string   "name"
    t.integer  "domain_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "hosts", ["domain_id"], :name => "index_hosts_on_domain_id"
  add_index "hosts", ["name"], :name => "index_hosts_on_name"

  create_table "muplugins", :force => true do |t|
    t.string   "plg_name"
    t.string   "graphite_name"
    t.string   "plg_title"
    t.string   "plg_info"
    t.integer  "category_id"
    t.integer  "host_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "muplugins", ["category_id"], :name => "index_muplugins_on_category_id"
  add_index "muplugins", ["host_id"], :name => "index_muplugins_on_host_id"
  add_index "muplugins", ["plg_name"], :name => "index_muplugins_on_plg_name"
  add_index "muplugins", ["plg_title"], :name => "index_muplugins_on_plg_title"

end
