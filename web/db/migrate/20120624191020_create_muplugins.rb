class CreateMuplugins < ActiveRecord::Migration
  def change
    create_table :muplugins do |t|
      t.string :plg_name
      t.string :graphite_name
      t.string :plg_title
      t.string :plg_info
      t.references :category
      t.references :host

      t.timestamps
    end
    add_index :muplugins, :category_id
    add_index :muplugins, :host_id
    add_index :muplugins, :plg_title
    add_index :muplugins, :plg_name
  end
end
