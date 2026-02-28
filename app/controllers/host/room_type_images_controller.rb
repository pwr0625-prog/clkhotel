module Host
  class RoomTypeImagesController < ApplicationController
    before_action :require_host!
    before_action :set_room_type
    before_action :set_image, only: %i[update destroy move_up move_down make_thumbnail]

    def create
      image = @room_type.room_images.build(image_params)
      image.entity_type = :room
      image.file.attach(image_params[:file]) if image_params[:file].present?

      if image.save
        redirect_to edit_host_room_type_path(@room_type), notice: "객실 이미지를 추가했습니다."
      else
        redirect_to edit_host_room_type_path(@room_type), alert: image.errors.full_messages.to_sentence
      end
    end

    def update
      @image.file.attach(image_params[:file]) if image_params[:file].present?

      if @image.update(image_params)
        redirect_to edit_host_room_type_path(@room_type), notice: "객실 이미지를 수정했습니다."
      else
        redirect_to edit_host_room_type_path(@room_type), alert: @image.errors.full_messages.to_sentence
      end
    end

    def destroy
      @image.destroy!
      normalize_sort_order!
      redirect_to edit_host_room_type_path(@room_type), notice: "객실 이미지를 삭제했습니다."
    end

    def move_up
      swap_with_neighbor!(:up)
      redirect_to edit_host_room_type_path(@room_type), notice: "정렬 순서를 변경했습니다."
    end

    def move_down
      swap_with_neighbor!(:down)
      redirect_to edit_host_room_type_path(@room_type), notice: "정렬 순서를 변경했습니다."
    end

    def make_thumbnail
      @image.update!(is_thumbnail: true)
      redirect_to edit_host_room_type_path(@room_type), notice: "썸네일 이미지를 지정했습니다."
    end

    private

    def set_room_type
      @room_type = RoomType.joins(:property)
                           .where(properties: { host_id: current_user.id })
                           .find(params[:room_type_id])
    end

    def set_image
      @image = @room_type.room_images.find(params[:id] || params[:image_id])
    end

    def image_params
      params.require(:image).permit(:image_url, :file, :is_thumbnail, :sort_order)
    end

    def swap_with_neighbor!(direction)
      images = @room_type.room_images.to_a
      index = images.index { |img| img.id == @image.id }
      return if index.nil?

      neighbor_index =
        if direction == :up
          index - 1
        else
          index + 1
        end
      return if neighbor_index.negative? || neighbor_index >= images.length

      neighbor = images[neighbor_index]
      current_sort = @image.sort_order
      neighbor_sort = neighbor.sort_order

      Image.transaction do
        @image.update!(sort_order: neighbor_sort)
        neighbor.update!(sort_order: current_sort)
      end
    end

    def normalize_sort_order!
      @room_type.room_images.ordered.each_with_index do |img, idx|
        img.update_column(:sort_order, idx + 1) if img.sort_order != idx + 1
      end
    end
  end
end
