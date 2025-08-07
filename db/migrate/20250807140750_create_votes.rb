class CreateVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :option, null: false, foreign_key: true
      t.references :poll, null: false, foreign_key: true

      t.timestamps
    end

    add_index :votes, [ :user_id, :poll_id ], unique: true, name: 'index_votes_on_user_and_poll'
  end
end
