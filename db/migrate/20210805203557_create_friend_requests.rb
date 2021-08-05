class CreateFriendRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :friend_requests do |t|
      t.references :sender_id, index: true, foreign_key: { to_table: :users }
      t.references :receiver_id, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
