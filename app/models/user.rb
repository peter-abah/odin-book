class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[facebook]

  validates :first_name, presence: true, length: { maximum: 25 }
  validates :last_name, presence: true, length: { maximum: 25 }
  validates :current_city, length: { maximum: 25 }
  validates :bio, length: { maximum: 150 }

  has_many :sent_friend_requests, class_name: 'FriendRequest',
                                  foreign_key: :sender_id, dependent: :destroy
  has_many :received_friend_requests, class_name: 'FriendRequest',
                                      foreign_key: :receiver_id,
                                      dependent: :destroy

  has_many :friendships, dependent: :destroy
  has_many :inverse_friendships, class_name: 'Friendship', foreign_key: :friend_id,
                                 dependent: :destroy

  has_many :likes, dependent: :destroy
  has_many :posts, -> { order(updated_at: :desc) }, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one_attached :profile_picture, dependent: :destroy
  has_one_attached :cover_image, dependent: :destroy

  before_create :set_default_images

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      # assuming the user model has a name, splits name into first and last name
      names = auth.info.name.split(' ')

      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.first_name = names[0]
      user.last_name = names.size == 1 ? '' : names[1]
      # user.image = auth.info.image # assuming the user model has an image
      # If you are using confirmable and the provider(s) you use validate emails, 
      # uncomment the line below to skip the confirmation emails.
      # user.skip_confirmation!
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def name
    "#{first_name} #{last_name}"
  end

  def all_posts
    friends_posts = friends.reduce([]) { |post_arr, friend| post_arr.concat(friend.posts) }
    posts_for_user = friends_posts + posts

    posts_for_user.sort do |post_a, post_b|
      post_b.updated_at <=> post_a.updated_at
    end
  end

  def friend?(user)
    friends.include?(user)
  end

  def friends
    friendships.map(&:friend) + inverse_friendships.map(&:user)
  end

  def friend_requests
    sent_friend_requests + recieved_friend_requests
  end

  def friend_request_for_user(user)
    sent_friend_requests.find_by(receiver_id: user.id) || received_friend_requests.find_by(sender_id: user.id)
  end

  def sent_request_to?(user)
    sent_friend_requests.exists?(receiver_id: user.id)
  end

  def received_request_from?(user)
    received_friend_requests.exists?(sender_id: user.id)
  end

  def request_exists_for?(user)
    sent_request_to?(user) || received_request_from?(user)
  end

  def send_request(user)
    sent_friend_requests.create!(receiver_id: user.id) unless request_exists_for?(user) || friend?(user)
  end

  def accept_request(friend_request)
    friendships.create!(friend_id: friend_request.sender_id) unless friend?(friend_request.sender)
    friend_request.destroy
  end

  def delete_request(friend_request)
    raise unless friend_request.sender == self || friend_request.receiver == self

    friend_request.delete
  end

  def remove_friend(friend)
    friendship = friendships.find_by(friend_id: friend.id) ||
                 inverse_friendships.find_by!(user_id: friend.id)
    friendship.destroy
  end

  def liked_post?(post)
    !like_for_post(post).nil?
  end

  def like_for_post(post)
    likes.find_by(post_id: post.id)
  end

  private

    # sets default profile image and cover image for new user
    def set_default_images
      file = File.open("#{Rails.root}/app/assets/images/default_profile_image.jpg")
      profile_picture.attach(io: file, filename: "profile_picture", content_type: 'image/jpg')

      file = File.open("#{Rails.root}/app/assets/images/default_cover_image.jpg")
      cover_image.attach(io: file, filename: "cover_image.jpg", content_type: 'image/jpg')
    end
end
