class RoomInventoryService
  Error = Class.new(StandardError)

  def self.available_for?(room_type, check_in_date, check_out_date, requested_rooms, exclude_booking_id: nil)
    new.available_for?(room_type, check_in_date, check_out_date, requested_rooms, exclude_booking_id: exclude_booking_id)
  end

  def self.reserve!(booking)
    new.reserve!(booking)
  end

  def self.release!(booking)
    new.release!(booking)
  end

  def available_for?(room_type, check_in_date, check_out_date, requested_rooms, exclude_booking_id: nil)
    requested = requested_rooms.to_i
    return false if requested <= 0

    stay_dates(check_in_date, check_out_date).all? do |date|
      snapshot_for(room_type, date, exclude_booking_id: exclude_booking_id)[:sellable_count] >= requested
    end
  end

  def reserve!(booking)
    adjust_booking_inventory!(booking, +booking.room_count.to_i)
  end

  def release!(booking)
    adjust_booking_inventory!(booking, -booking.room_count.to_i)
  end

  def snapshot_for(room_type, date, exclude_booking_id: nil)
    row = room_type.room_availabilities.find_by(date: date)
    available_count = row&.available_count || room_type.total_count
    closed = row&.is_closed? || false

    booked_count =
      if row
        row.booked_count.to_i
      else
        bookings_overlap_count(room_type, date, exclude_booking_id: exclude_booking_id)
      end

    if row && exclude_booking_id.present?
      current_booking = room_type.bookings.find_by(id: exclude_booking_id)
      if current_booking && current_booking_holds_inventory?(current_booking) && covers_date?(current_booking, date)
        booked_count -= current_booking.room_count.to_i
      end
    end

    {
      row: row,
      available_count: available_count,
      booked_count: [booked_count, 0].max,
      sellable_count: closed ? 0 : [available_count - booked_count, 0].max,
      is_closed: closed
    }
  end

  private

  def adjust_booking_inventory!(booking, delta)
    return if delta.zero?
    return unless booking.room_type.present?
    return if booking.check_in_date.blank? || booking.check_out_date.blank?

    booking.room_type.with_lock do
      stay_dates(booking.check_in_date, booking.check_out_date).each do |date|
        row = booking.room_type.room_availabilities.lock.find_or_initialize_by(date: date)
        row.available_count = booking.room_type.total_count if row.new_record?
        row.booked_count ||= 0
        row.is_closed = false if row.is_closed.nil?

        next_booked = row.booked_count.to_i + delta
        raise Error, "#{date} 재고 계산 중 오류가 발생했습니다" if next_booked.negative?

        if delta.positive?
          if row.is_closed?
            raise Error, "#{date} 날짜는 판매 마감 상태입니다"
          end

          if next_booked > row.available_count.to_i
            raise Error, "#{date} 날짜의 남은 객실 수가 부족합니다"
          end
        end

        row.booked_count = next_booked
        row.save!
      end
    end
  end

  def stay_dates(check_in_date, check_out_date)
    return [] if check_in_date.blank? || check_out_date.blank? || check_out_date <= check_in_date

    (check_in_date...check_out_date).to_a
  end

  def bookings_overlap_count(room_type, date, exclude_booking_id: nil)
    scope = room_type.bookings.where.not(status: :cancelled)
    scope = scope.where.not(id: exclude_booking_id) if exclude_booking_id.present?
    scope.where("check_in_date <= ? AND check_out_date > ?", date, date).sum(:room_count)
  end

  def current_booking_holds_inventory?(booking)
    booking.pending? || booking.awaiting_payment? || booking.confirmed?
  end

  def covers_date?(booking, date)
    booking.check_in_date <= date && booking.check_out_date > date
  end
end
