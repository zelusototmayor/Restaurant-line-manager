require 'csv'
require 'json'

class TableManager
  attr_reader :config, :live_tables, :historical_data

  def initialize
    load_config
    load_live_tables
    load_historical_data
  end

  # Get all tables with a specific status
  def tables_by_status(status)
    @live_tables.select { |t| t[:status] == status }
  end

  # Get free tables
  def free_tables
    tables_by_status('free')
  end

  # Get occupied tables (including bill_printed and cleaning)
  def occupied_tables
    @live_tables.reject { |t| t[:status] == 'free' }
  end

  # Find tables that can accommodate a party size
  def find_suitable_tables(party_size)
    # First, check for exact fit or slightly larger free tables
    suitable_free = free_tables.select { |t| t[:table_size] >= party_size }

    # Sort by size (prefer smaller tables first)
    suitable_free.sort_by { |t| t[:table_size] }
  end

  # Calculate average duration for a party size from historical data
  def average_duration_for_party_size(party_size, time_period = :dinner)
    matching_records = @historical_data.select do |record|
      record[:party_size] == party_size
    end

    return 75 if matching_records.empty? # Default 75 minutes

    total_duration = matching_records.sum { |r| r[:duration] }
    (total_duration.to_f / matching_records.count).round
  end

  # Get tables that might become available soon
  def tables_finishing_soon(within_minutes = 30)
    now = Time.now

    occupied_tables.select do |table|
      next false if table[:est_finish_time].nil? || table[:est_finish_time].empty?

      finish_time = Time.parse(table[:est_finish_time])
      minutes_until_free = ((finish_time - now) / 60).round

      minutes_until_free > 0 && minutes_until_free <= within_minutes
    end.sort_by do |table|
      Time.parse(table[:est_finish_time])
    end
  end

  # Calculate average wait time based on current state
  def estimated_wait_for_party_size(party_size)
    # Check if there are free suitable tables
    free_suitable = find_suitable_tables(party_size)

    if free_suitable.any?
      # Table available now (with small buffer for seating)
      return { min: 0, max: 5, status: :available_now }
    end

    # Look at tables finishing soon
    finishing_soon = tables_finishing_soon(60)
    suitable_finishing = finishing_soon.select { |t| t[:table_size] >= party_size }

    if suitable_finishing.any?
      now = Time.now
      finish_times = suitable_finishing.map do |table|
        Time.parse(table[:est_finish_time])
      end

      # Take the earliest available table
      earliest = finish_times.min
      minutes_until_available = ((earliest - now) / 60).round

      # Add 5-10 minutes for cleaning/turnover
      min_wait = [minutes_until_available + 5, 5].max
      max_wait = minutes_until_available + 10

      return { min: min_wait, max: max_wait, status: :waiting }
    end

    # No suitable tables available soon - estimate based on averages
    avg_duration = average_duration_for_party_size(party_size)
    occupied_count = occupied_tables.count
    free_count = free_tables.count
    total_tables = @live_tables.count

    # Calculate occupancy rate
    occupancy_rate = occupied_count.to_f / total_tables

    # Higher occupancy means longer wait
    wait_multiplier = 1 + (occupancy_rate * 0.5)

    base_wait = (avg_duration * 0.3).round # Assume some turnover
    min_wait = (base_wait * wait_multiplier).round
    max_wait = (min_wait * 1.5).round

    { min: min_wait, max: max_wait, status: :busy }
  end

  # Reload live data (useful after regenerating)
  def reload_live_data
    load_live_tables
  end

  private

  def load_config
    config_path = Rails.root.join('data', 'tables_config.json')
    @config = JSON.parse(File.read(config_path), symbolize_names: true)
  end

  def load_live_tables
    csv_path = Rails.root.join('data', 'tables_live.csv')

    @live_tables = []
    CSV.foreach(csv_path, headers: true, header_converters: :symbol) do |row|
      @live_tables << {
        table_id: row[:table_id].to_i,
        table_size: row[:table_size].to_i,
        status: row[:status],
        start_time: row[:start_time],
        num_people: row[:num_people].to_i,
        elapsed_time: row[:elapsed_time].to_i,
        est_finish_time: row[:est_finish_time]
      }
    end
  end

  def load_historical_data
    csv_path = Rails.root.join('data', 'tables_history.csv')

    @historical_data = []
    CSV.foreach(csv_path, headers: true, header_converters: :symbol) do |row|
      @historical_data << {
        date: Date.parse(row[:date]),
        table_id: row[:table_id].to_i,
        party_size: row[:party_size].to_i,
        start_time: Time.parse(row[:start_time]),
        finish_time: Time.parse(row[:finish_time]),
        duration: row[:duration].to_i,
        num_dishes: row[:num_dishes].to_i,
        coffee: row[:coffee] == 'true',
        alcoholic_drinks: row[:alcoholic_drinks] == 'true'
      }
    end
  end
end
