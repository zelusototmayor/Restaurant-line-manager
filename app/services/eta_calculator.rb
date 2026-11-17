class EtaCalculator
  def initialize(table_manager = nil)
    @table_manager = table_manager || TableManager.new
  end

  # Main method to calculate ETA for a party size
  def calculate(party_size)
    # Validate party size
    return error_response("Party size must be between 1 and 12") unless valid_party_size?(party_size)

    # Get estimate from table manager
    estimate = @table_manager.estimated_wait_for_party_size(party_size)

    # Format and return response
    {
      success: true,
      party_size: party_size,
      eta_min: estimate[:min],
      eta_max: estimate[:max],
      status: estimate[:status],
      message: format_message(estimate)
    }
  rescue StandardError => e
    error_response("An error occurred: #{e.message}")
  end

  # Get current restaurant statistics
  def restaurant_stats
    {
      total_tables: @table_manager.live_tables.count,
      free_tables: @table_manager.free_tables.count,
      occupied_tables: @table_manager.occupied_tables.count,
      occupancy_rate: calculate_occupancy_rate
    }
  end

  # Check if we can accommodate a party size at all
  def can_accommodate?(party_size)
    max_table_size = @table_manager.live_tables.map { |t| t[:table_size] }.max
    party_size <= max_table_size
  end

  private

  def valid_party_size?(party_size)
    party_size.is_a?(Integer) && party_size >= 1 && party_size <= 12
  end

  def calculate_occupancy_rate
    total = @table_manager.live_tables.count
    occupied = @table_manager.occupied_tables.count
    return 0 if total.zero?

    ((occupied.to_f / total) * 100).round(1)
  end

  def format_message(estimate)
    case estimate[:status]
    when :available_now
      "Great news! We have tables available now."
    when :waiting
      "We're currently preparing a table for you."
    when :busy
      "We're quite busy right now, but we'll seat you as soon as possible."
    else
      "Estimated wait time calculated."
    end
  end

  def error_response(message)
    {
      success: false,
      error: message,
      eta_min: nil,
      eta_max: nil
    }
  end
end
