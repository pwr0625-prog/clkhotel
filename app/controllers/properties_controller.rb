class PropertiesController < ApplicationController
  def index
    @filters = search_params.to_h.symbolize_keys
    @properties = Property.approved.includes(:room_types, :host)

    if @filters[:q].present?
      keyword = "%#{@filters[:q].strip}%"
      @properties = @properties.where("property_name LIKE ? OR city LIKE ? OR address LIKE ?", keyword, keyword, keyword)
    end

    @properties = @properties.where(city: @filters[:city]) if @filters[:city].present?

    if @filters[:guests].present?
      guests = @filters[:guests].to_i
      @properties = @properties.joins(:room_types).where("room_types.max_guests >= ?", guests).distinct if guests.positive?
    end

    @properties = @properties.order(created_at: :desc)
    @cities = Property.approved.distinct.order(:city).pluck(:city)
  end

  def show
    @property = Property.includes(:room_types, reviews: :user, amenities: []).find(params[:id])
    if @property.closed_for_guest? && !can_access_closed_property?(@property)
      redirect_to properties_path, alert: "현재 준비중인 숙소입니다."
      return
    end

    @booking = Booking.new(
      check_in_date: params[:check_in_date],
      check_out_date: params[:check_out_date],
      guest_count: params[:guest_count].presence || 1,
      room_count: 1
    )
    @wishlist = logged_in? ? current_user.wishlists.find_by(property: @property) : nil
  end

  private

  def search_params
    params.permit(:q, :city, :check_in_date, :check_out_date, :guests)
  end

  def can_access_closed_property?(property)
    return false unless logged_in?
    return true if current_user.admin?

    current_user.host? && property.host_id == current_user.id
  end
end
