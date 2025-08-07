class CreateOptions < ActiveRecord::Migration[8.0]
  def change
    create_table :options do |t|
      t.string :text, null: false
      t.references :poll, null: false, foreign_key: true
      t.integer :votes_count, default: 0, null: false

      t.timestamps
    end
  end
end
