class PostsController < ApplicationController
  PER_PAGE = 5

  before_action :set_post, only: %i[show edit update destroy]

  def index
    requested_page = params.fetch(:page, 1).to_i
    @current_page = requested_page.positive? ? requested_page : 1

    posts_scope = Post.order(created_at: :desc)
    @total_pages = (posts_scope.count.to_f / PER_PAGE).ceil
    @total_pages = 1 if @total_pages.zero?
    @current_page = [@current_page, @total_pages].min

    offset = (@current_page - 1) * PER_PAGE
    @posts = posts_scope.offset(offset).limit(PER_PAGE)
  end

  def show; end

  def new
    @post = Post.new
  end

  def edit; end

  def create
    @post = Post.new(post_params)
    @post.author_name = current_user&.name.presence || "익명"

    if @post.save
      redirect_to @post, notice: "게시글이 생성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "게시글이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "게시글이 삭제되었습니다."
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :content, :likes_count, :comments_count)
  end
end
