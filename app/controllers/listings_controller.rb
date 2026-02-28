class ListingsController < ApplicationController
  before_action :set_listing, only: %i[show edit update]
  before_action :require_login!, only: %i[new create edit update]
  before_action :require_host!, only: %i[new create edit update]
  before_action :require_listing_host!, only: %i[edit update]
  before_action :require_guest!, only: %i[search]

  def index
    @listings = Listing.includes(:host).order(created_at: :desc)
  end

  def show
    @booking = Booking.new
    @host_pending_bookings = @listing.bookings.pending.includes(:guest).order(created_at: :desc)
    @availability = availability_preview
  end

  def new
    @listing = Listing.new
  end

  def create
    @listing = current_user.hosted_listings.build(listing_params)

    if @listing.save
      redirect_to @listing, notice: "hostel가 등록되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @listing.update(listing_params)
      redirect_to @listing, notice: "hostel 정보가 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def search
    @search = search_params
    @results = Listing.includes(:host).order(created_at: :desc)
    @listing_options = Listing.order(:title)

    filter_by_listing!
    filter_by_location!
    filter_by_guests_count!
    filter_by_availability!
  end

  private

  def set_listing
    @listing = Listing.find(params[:id])
  end

  def require_listing_host!
    return if @listing.host_id == current_user.id

    redirect_to listings_path, alert: "본인이 등록한 hostel만 수정할 수 있습니다."
  end

  def listing_params
    params.require(:listing).permit(
      :title,
      :description,
      :location,
      :price,
      :capacity,
      :room_types,
      :rate_details,
      :other_details,
      photos: []
    )
  end

  def search_params
    params.fetch(:search, {}).permit(:listing_id, :location, :check_in, :check_out, :guests_count)
  end

  def filter_by_listing!
    listing_id = @search[:listing_id].to_i
    return if listing_id <= 0

    @results = @results.where(id: listing_id)
  end

  def availability_preview
    check_in_text = params[:check_in].to_s
    check_out_text = params[:check_out].to_s
    return nil if check_in_text.blank? || check_out_text.blank?

    check_in = Date.iso8601(check_in_text)
    check_out = Date.iso8601(check_out_text)

    @listing.available_for?(check_in, check_out)
  rescue Date::Error
    nil
  end

  def filter_by_location!
    location = @search[:location].to_s.strip
    return if location.blank?

    @results = @results.where("location LIKE ?", "%#{location}%")
  end

  def filter_by_guests_count!
    guests = @search[:guests_count].to_i
    return if guests <= 0

    @results = @results.where("capacity >= ?", guests)
  end

  def filter_by_availability!
    check_in_text = @search[:check_in].to_s
    check_out_text = @search[:check_out].to_s
    return if check_in_text.blank? || check_out_text.blank?

    check_in = Date.iso8601(check_in_text)
    check_out = Date.iso8601(check_out_text)
    if check_out <= check_in
      @results = Listing.none
      flash.now[:alert] = "체크아웃 날짜는 체크인보다 뒤여야 합니다."
      return
    end

    overlapping = Booking.where.not(status: :cancelled)
                         .where("check_in < ? AND check_out > ?", check_out, check_in)
                         .select(:listing_id)

    @results = @results.where.not(id: overlapping)
  rescue Date::Error
    @results = Listing.none
    flash.now[:alert] = "날짜 형식이 올바르지 않습니다."
  end
end
