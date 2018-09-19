class CreateFacilitators < ActiveRecord::Migration
  def change
    create_table :facilitators do |t|
      t.references :user, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end
  end
end
