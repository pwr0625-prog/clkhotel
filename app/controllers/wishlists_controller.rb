class WishlistsController < ApplicationController
  before_action :require_login!
  before_action :set_property

  def create
    current_user.wishlists.find_or_create_by!(property: @property)
    redirect_to property_path(@property), notice: "찜 목록에 추가했습니다."
  end

  def destroy
    current_user.wishlists.find(params[:id]).destroy!
    redirect_to property_path(@property), notice: "찜 목록에서 제거했습니다."
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end
end
