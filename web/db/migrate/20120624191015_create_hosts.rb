class CreateHosts < ActiveRecord::Migration
  def change
    create_table :hosts do |t|
      t.string :name
      t.references :domain

      t.timestamps
    end
    add_index :hosts, :name
    add_index :hosts, :domain_id
  end
end
