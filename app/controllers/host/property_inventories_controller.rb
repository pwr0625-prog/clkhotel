module Host
  class PropertyInventoriesController < ApplicationController
    before_action :require_host!
    before_action :set_property
    before_action :set_range
    before_action :set_room_types

    def show
      load_calendar_data
      load_selected_date_rows
      load_booking_timeline
    end

    def update
      inventory_params = params.fetch(:inventory, {})
      from_date = parse_date(inventory_params[:from_date]) || @from_date
      to_date = parse_date(inventory_params[:to_date]) || @to_date
      if to_date < from_date
        return redirect_to host_property_inventory_path(@property, from: @from_date, to: @to_date),
                           alert: "종료일은 시작일 이후여야 합니다."
      end

      is_closed = ActiveModel::Type::Boolean.new.cast(inventory_params[:is_closed]) if inventory_params.key?(:is_closed)

      ActiveRecord::Base.transaction do
        @room_types.each do |room_type|
          room_type.with_lock do
            (from_date..to_date).each do |date|
              row = room_type.room_availabilities.lock.find_or_initialize_by(date: date)
              row.available_count = room_type.total_count if row.new_record?
              row.booked_count ||= 0
              row.is_closed = false if row.new_record? && row.is_closed.nil?
              row.is_closed = is_closed unless is_closed.nil?
              row.save!
            end
          end
        end
      end

      redirect_to host_property_inventory_path(@property, from: from_date, to: to_date),
                  notice: "호텔 전체 판매 상태를 저장했습니다."
    rescue ActiveRecord::RecordInvalid => e
      load_calendar_data
      load_selected_date_rows
      load_booking_timeline
      flash.now[:alert] = e.record.errors.full_messages.to_sentence.presence || "재고 저장에 실패했습니다."
      render :show, status: :unprocessable_entity
    end

    private

    def set_property
      @property = current_user.properties.find(params[:property_id])
    end

    def set_room_types
      @room_types = @property.room_types.order(:created_at)
    end

    def set_range
      @from_date = parse_date(params[:from]) || Date.current
      @to_date = parse_date(params[:to]) || (@from_date + 13.days)
      @to_date = @from_date if @to_date < @from_date
    end

    def load_calendar_data
      @calendar_month = parse_month(params[:month]) || @from_date.beginning_of_month
      @calendar_start_date = @calendar_month.beginning_of_month.beginning_of_week(:sunday)
      @calendar_end_date = @calendar_month.end_of_month.end_of_week(:sunday)
      @calendar_dates = (@calendar_start_date..@calendar_end_date).to_a

      service = ::RoomInventoryService.new
      @calendar_totals = @calendar_dates.each_with_object({}) do |date, result|
        total_available = 0
        total_booked = 0
        total_sellable = 0
        closed_count = 0

        @room_types.each do |room_type|
          snapshot = service.snapshot_for(room_type, date)
          total_available += snapshot[:available_count].to_i
          total_booked += snapshot[:booked_count].to_i
          total_sellable += snapshot[:sellable_count].to_i
          closed_count += 1 if snapshot[:is_closed]
        end

        result[date] = {
          available_count: total_available,
          booked_count: total_booked,
          sellable_count: total_sellable,
          all_closed: @room_types.present? && closed_count == @room_types.size
        }
      end

      @calendar_bookings_by_date = build_calendar_bookings
      @selected_date = parse_date(params[:selected_date])
      @selected_date = nil unless @selected_date && @calendar_dates.include?(@selected_date)
      @selected_date ||= Date.current if @calendar_dates.include?(Date.current)
      @selected_date ||= @calendar_month.beginning_of_month
      @selected_date_bookings = @calendar_bookings_by_date[@selected_date] || []
    end

    def load_selected_date_rows
      service = ::RoomInventoryService.new
      @selected_date_rows = @room_types.map do |room_type|
        [room_type, service.snapshot_for(room_type, @selected_date)]
      end
    end

    def build_calendar_bookings
      grouped = Hash.new { |hash, key| hash[key] = [] }
      bookings = Booking.includes(:user, :room_type)
                        .joins(:room_type)
                        .where(room_types: { property_id: @property.id })
                        .where.not(status: :cancelled)
                        .where("check_in_date <= ? AND check_out_date > ?", @calendar_end_date, @calendar_start_date)

      bookings.each do |booking|
        visible_start = [booking.check_in_date, @calendar_start_date].max
        visible_end = [booking.check_out_date - 1.day, @calendar_end_date].min
        next if visible_end < visible_start

        (visible_start..visible_end).each { |date| grouped[date] << booking }
      end

      grouped
    end

    def parse_date(value)
      return if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def parse_month(value)
      return if value.blank?

      Date.strptime(value.to_s, "%Y-%m").beginning_of_month
    rescue ArgumentError
      nil
    end

    def load_booking_timeline
      @timeline_start_date = @calendar_month.beginning_of_month
      @timeline_end_date = @calendar_month.end_of_month
      @timeline_dates = (@timeline_start_date..@timeline_end_date).to_a

      @timeline_rows = []
      row_map = {}

      @room_types.each do |room_type|
        room_numbers = room_type.room_numbers
        room_numbers = (1..room_type.total_count.to_i).map { |index| "미지정-#{index}" } if room_numbers.empty?

        room_numbers.each do |room_number|
          row = {
            room_type: room_type,
            room_number: room_number,
            label: "#{room_type.room_name} / #{room_number}",
            bars: []
          }
          @timeline_rows << row
          row_map[[room_type.id, room_number]] = row
        end
      end

      bookings = Booking.includes(:user, :room_type)
                        .joins(:room_type)
                        .where(room_types: { property_id: @property.id })
                        .where.not(status: :cancelled)
                        .where("check_in_date <= ? AND check_out_date > ?", @timeline_end_date, @timeline_start_date)

      bookings.each do |booking|
        assigned_numbers = booking.assigned_room_numbers
        next if assigned_numbers.empty?

        start_date = [booking.check_in_date, @timeline_start_date].max
        end_date = [booking.check_out_date - 1.day, @timeline_end_date].min
        next if end_date < start_date

        start_index = (start_date - @timeline_start_date).to_i + 1
        span = (end_date - start_date).to_i + 1

        assigned_numbers.each do |room_number|
          row = row_map[[booking.room_type_id, room_number]]
          next unless row

          row[:bars] << {
            start_index: start_index,
            span: span,
            guest_name: booking.user.name,
            booking_code: booking.booking_code
          }
        end
      end

      @timeline_rows.each do |row|
        row[:bars].sort_by! { |bar| [bar[:start_index], -bar[:span]] }
      end
    end
  end
end
