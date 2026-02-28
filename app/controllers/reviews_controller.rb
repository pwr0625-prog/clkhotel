class ReviewsController < ApplicationController
  before_action :require_login!
  before_action :set_booking

  def create
    unless @booking.user_id == current_user.id
      return redirect_to booking_path(@booking), alert: "리뷰 작성 권한이 없습니다."
    end

    unless @booking.can_review?
      return redirect_to booking_path(@booking), alert: "숙박 완료 후 리뷰를 작성할 수 있습니다."
    end

    @review = @booking.review || @booking.build_review(user: current_user, property: @booking.property)
    @review.assign_attributes(review_params.merge(user: current_user, property: @booking.property))

    if @review.save
      redirect_to booking_path(@booking), notice: "리뷰가 저장되었습니다."
    else
      redirect_to booking_path(@booking), alert: @review.errors.full_messages.to_sentence
    end
  end

  private

  def set_booking
    @booking = Booking.includes(:review, room_type: :property).find(params[:booking_id] || params[:id])
  end

  def review_params
    params.require(:review).permit(:rating_overall, :rating_cleanliness, :rating_location, :rating_service, :rating_value, :content)
  end
end
