module Host
  class PropertyImagesController < ApplicationController
    before_action :require_host!
    before_action :set_property

    def create
      image = Image.where(entity_type: :property, entity_id: @property.id).first_or_initialize
      image.assign_attributes(
        image_url: image_params[:image_url],
        entity_type: :property,
        entity_id: @property.id,
        is_thumbnail: true,
        sort_order: 1
      )
      image.file.attach(image_params[:file]) if image_params[:file].present?

      if image.save
        redirect_to host_property_path(@property), notice: "숙소 대표 이미지를 저장했습니다."
      else
        redirect_to host_property_path(@property), alert: image.errors.full_messages.to_sentence
      end
    end

    private

    def set_property
      @property = current_user.properties.find(params[:property_id])
    end

    def image_params
      params.require(:image).permit(:image_url, :file)
    end
  end
end
