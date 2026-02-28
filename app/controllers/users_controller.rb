class UsersController < ApplicationController
  before_action :set_user, only: %i[show]

  def new
    @user = User.new(user_type: :guest)
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      redirect_to @user, notice: "회원가입이 완료되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone, :user_type, :password, :password_confirmation)
  end
end
