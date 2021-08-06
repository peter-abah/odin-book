class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :sent_friend_requests, class_name: 'FriendRequest',
                                  foreign_key: :sender_id, dependent: :destroy
  has_many :recieved_friend_requests, class_name: 'FriendRequest',
                                      foreign_key: :receiver_id,
                                      dependent: :destroy

  has_many :friendships, dependent: :destroy
  has_many :inverse_friendships, class_name: 'Friendship', foreign_key: :friend_id,
                                 dependent: :destroy

  def friends
    friendships.map(&:friend) + inverse_friendships.map(&:user)
  end

  def accept_request(friend_request)
    Friendship.create(user_id: friend_request.sender_id,
                      friend_id: friend_request.receiver_id)
    friend_request.destroy
  end

  def delete_request(friend_request)
    raise unless friend_request.sender == self || friend_request.receiver == self
    
    friend_request.delete
  end

  def remove_friend(friend)
    friendship = friendships.find_by(friend_id: friend.id) ||
                  inverse_friendships.find_by(user_id: friend.id)
    friendship.destroy
  end
end
