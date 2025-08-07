class CreatePolls < ActiveRecord::Migration[8.0]
  def change
    create_table :polls do |t|
      t.string :title, null: false
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.boolean :active, default: true, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :polls, :active
    add_index :polls, :expires_at
  end
end
