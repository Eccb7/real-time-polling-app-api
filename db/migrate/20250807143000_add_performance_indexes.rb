class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Indexes for common query patterns
    add_index :polls, [ :active, :expires_at ], name: 'index_polls_on_active_and_expires_at'
    add_index :polls, [ :user_id, :created_at ], name: 'index_polls_on_user_and_created_at'
    add_index :polls, :created_at, name: 'index_polls_on_created_at'

    # Composite index for votes queries
    add_index :votes, [ :poll_id, :created_at ], name: 'index_votes_on_poll_and_created_at'
    add_index :votes, [ :user_id, :created_at ], name: 'index_votes_on_user_and_created_at'

    # Index for options queries
    add_index :options, [ :poll_id, :votes_count ], name: 'index_options_on_poll_and_votes_count'

    # Partial indexes for active polls only
    add_index :polls, :expires_at, where: 'active = true', name: 'index_active_polls_on_expires_at'
  end
end
