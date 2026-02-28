module Host
  class RoomTypesController < ApplicationController
    before_action :require_host!
    before_action :set_room_type

    def edit; end

    def update
      if @room_type.update(room_type_params)
        redirect_to host_property_path(@room_type.property), notice: "객실 유형을 수정했습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_room_type
      @room_type = RoomType.joins(:property)
                           .where(properties: { host_id: current_user.id })
                           .find(params[:id])
    end

    def room_type_params
      params.require(:room_type).permit(
        :room_name,
        :room_type,
        :bed_type,
        :max_guests,
        :base_price,
        :currency,
        :area_sqm,
        :floor,
        :view_type,
        :total_count,
        :is_smoking,
        :cancellation_policy_name
      )
    end
  end
end
