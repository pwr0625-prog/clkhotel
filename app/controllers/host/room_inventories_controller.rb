module Host
  class RoomInventoriesController < ApplicationController
    before_action :require_host!
    before_action :set_room_type
    before_action :set_range

    def show
      load_inventory_rows
    end

    def update
      inventory_params = params.fetch(:inventory, {})
      room_numbers_key_present = params[:inventory]&.key?(:room_numbers_text)
      room_numbers_text = inventory_params[:room_numbers_text]
      inventory_fields_present = %i[available_count is_closed price_override].any? { |key| inventory_params.key?(key) }

      from_date = parse_date(inventory_params[:from_date]) || @from_date
      to_date = parse_date(inventory_params[:to_date]) || @to_date
      if to_date < from_date
        return redirect_to host_room_type_inventory_path(@room_type, from: @from_date, to: @to_date),
                           alert: "종료일은 시작일 이후여야 합니다."
      end

      available_count = integer_param(inventory_params[:available_count])
      is_closed = ActiveModel::Type::Boolean.new.cast(inventory_params[:is_closed]) if inventory_params.key?(:is_closed)
      price_override = decimal_param(inventory_params[:price_override]) if inventory_params.key?(:price_override)

      ActiveRecord::Base.transaction do
        @room_type.with_lock do
          if room_numbers_key_present
            @room_type.room_numbers_text = room_numbers_text
            @room_type.save!
          end

          if inventory_fields_present
            (from_date..to_date).each do |date|
              row = @room_type.room_availabilities.lock.find_or_initialize_by(date: date)
              row.available_count = @room_type.total_count if row.new_record?
              row.booked_count ||= 0
              row.is_closed = false if row.new_record? && row.is_closed.nil?
              row.available_count = available_count if !available_count.nil?
              row.is_closed = is_closed unless is_closed.nil?
              row.price_override = price_override if inventory_params.key?(:price_override)
              row.save!
            end
          end
        end
      end

      redirect_to host_room_type_inventory_path(@room_type, from: from_date, to: to_date),
                  notice: "재고 설정을 저장했습니다."
    rescue ActiveRecord::RecordInvalid => e
      load_inventory_rows
      flash.now[:alert] = e.record.errors.full_messages.to_sentence.presence || "재고 저장에 실패했습니다."
      render :show, status: :unprocessable_entity
    end

    private

    def set_room_type
      @room_type = RoomType.joins(:property)
                           .where(properties: { host_id: current_user.id })
                           .includes(:property)
                           .find(params[:room_type_id])
    end

    def set_range
      @from_date = parse_date(params[:from]) || Date.current
      @to_date = parse_date(params[:to]) || (@from_date + 13.days)
      @to_date = @from_date if @to_date < @from_date
    end

    def load_inventory_rows
      rows_by_date = @room_type.room_availabilities.where(date: @from_date..@to_date).index_by(&:date)
      service = ::RoomInventoryService.new

      @inventory_rows = (@from_date..@to_date).map do |date|
        row = rows_by_date[date]
        row ||= @room_type.room_availabilities.build(date: date, available_count: @room_type.total_count, booked_count: 0)
        snapshot = service.snapshot_for(@room_type, date)
        [row, snapshot]
      end
    end

    def parse_date(value)
      return if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def integer_param(value)
      return nil if value.blank?

      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end

    def decimal_param(value)
      return nil if value.blank?

      BigDecimal(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
