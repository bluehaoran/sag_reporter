class CreateLanguages < ActiveRecord::Migration
  def change
    create_table :languages do |t|
      t.string :name
      t.text :description
      t.boolean :lwc

      t.timestamps null: false
    end
  end
end
