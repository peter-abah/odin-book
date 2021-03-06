class PostsController < ApplicationController
  before_action :set_post, only: %i[show edit update destroy]

  def index
    @posts = current_user.all_posts
    @post = current_user.posts.build
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to posts_path
    else
      render :new
    end
  end

  def show
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post
    else
      render :edit
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_url
  end

  private

    def post_params
      params.require(:post).permit(:body, images: [])
    end

    def set_post
      @post = Post.find(params[:id])
    end
end
