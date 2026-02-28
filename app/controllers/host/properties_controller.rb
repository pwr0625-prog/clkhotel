module Host
  class PropertiesController < ApplicationController
    before_action :require_host!
    before_action :set_property, only: %i[show edit update destroy create_room_type]

    def index
      @properties = current_user.properties.includes(:room_types).order(created_at: :desc)
    end

    def new
      @property = current_user.properties.build(check_in_time: "15:00", check_out_time: "11:00")
    end

    def create
      @property = current_user.properties.build(property_params)
      if @property.save
        redirect_to host_property_path(@property), notice: "숙소를 등록했습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @room_type = @property.room_types.build(currency: @property.host.currency.presence || "KRW")
    end

    def edit; end

    def update
      if @property.update(property_params)
        redirect_to host_property_path(@property), notice: "숙소 정보를 수정했습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @property.destroy
      redirect_to host_properties_path, notice: "숙소를 삭제했습니다."
    end

    def create_room_type
      room_type = @property.room_types.build(room_type_params)
      if room_type.save
        redirect_to host_property_path(@property), notice: "객실 유형을 추가했습니다."
      else
        @room_type = room_type
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_property
      @property = current_user.properties.find(params[:id])
    end

    def property_params
      permitted = params.require(:property).permit(:property_name, :property_type, :description, :country, :city, :address, :latitude, :longitude, :star_rating, :check_in_time, :check_out_time, :is_approved, :is_open)
      if params[:property].key?(:is_open)
        permitted[:is_open] = ActiveModel::Type::Boolean.new.cast(params[:property][:is_open])
      end
      permitted
    end

    def room_type_params
      params.require(:room_type).permit(:room_name, :room_type, :bed_type, :max_guests, :base_price, :currency, :area_sqm, :floor, :view_type, :total_count, :is_smoking, :cancellation_policy_name)
    end
  end
end
