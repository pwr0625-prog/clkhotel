class WelcomeController < ApplicationController
  def index
    @featured_properties = Property.approved.includes(:room_types).order(is_open: :desc, created_at: :desc).limit(6)
    @popular_cities = Property.approved.group(:city).order(Arel.sql("COUNT(*) DESC")).limit(8).count.keys
  end

  def design; end
end
