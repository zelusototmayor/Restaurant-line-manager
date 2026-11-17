require 'csv'
require 'json'

namespace :data do
  desc "Generate live restaurant state (current table status)"
  task generate_live: :environment do
    puts "Generating live data..."

    # Load table configuration
    config_path = Rails.root.join('data', 'tables_config.json')
    tables_config = JSON.parse(File.read(config_path))

    # Build table list with IDs
    all_tables = []
    table_id = 1
    tables_config.each do |config|
      config['count'].times do
        all_tables << { id: table_id, size: config['size'] }
        table_id += 1
      end
    end

    # Simulate dinner rush - FULL RESTAURANT (95-100% occupancy)
    # Line manager only useful when restaurant is full!
    occupancy_rate = 0.95 + (rand * 0.05) # 95-100%
    num_occupied = (all_tables.count * occupancy_rate).to_i

    # Current time (simulate dinner rush at 20:00)
    current_time = Time.now.change(hour: 20, min: 0, sec: 0)

    # Shuffle tables and assign statuses
    shuffled_tables = all_tables.shuffle
    live_data = []

    shuffled_tables.each_with_index do |table, index|
      if index < num_occupied
        # Table is in use
        status_roll = rand

        if status_roll < 0.7
          # Occupied (70% of occupied tables)
          status = 'occupied'

          # Random party size
          party_size = [[1, 2, 2, 3, 3, 4, 4, 4, 5, 6].sample, table[:size]].min

          # Started 15-90 minutes ago
          elapsed_time = rand(15..90)
          start_time = current_time - (elapsed_time * 60)

          # Estimate remaining time based on elapsed time and party size
          # Average meal is 75 minutes, but varies by party size
          expected_duration = 60 + (party_size * 5)
          remaining_time = [expected_duration - elapsed_time, 5].max # At least 5 min remaining
          est_finish_time = current_time + (remaining_time * 60)

          live_data << {
            table_id: table[:id],
            table_size: table[:size],
            status: status,
            start_time: start_time.strftime('%Y-%m-%d %H:%M:%S'),
            num_people: party_size,
            elapsed_time: elapsed_time,
            est_finish_time: est_finish_time.strftime('%Y-%m-%d %H:%M:%S')
          }

        elsif status_roll < 0.85
          # Bill printed (15% of occupied tables)
          status = 'bill_printed'

          party_size = [[2, 2, 3, 4, 4, 5].sample, table[:size]].min

          # Started 60-110 minutes ago
          elapsed_time = rand(60..110)
          start_time = current_time - (elapsed_time * 60)

          # Should finish in 5-15 minutes
          remaining_time = rand(5..15)
          est_finish_time = current_time + (remaining_time * 60)

          live_data << {
            table_id: table[:id],
            table_size: table[:size],
            status: status,
            start_time: start_time.strftime('%Y-%m-%d %H:%M:%S'),
            num_people: party_size,
            elapsed_time: elapsed_time,
            est_finish_time: est_finish_time.strftime('%Y-%m-%d %H:%M:%S')
          }

        else
          # Cleaning (15% of occupied tables)
          status = 'cleaning'

          # No people, just cleaning time
          # Cleaning takes 5-10 minutes, started 0-8 minutes ago
          elapsed_time = rand(0..8)
          start_time = current_time - (elapsed_time * 60)
          remaining_time = rand(2..7)
          est_finish_time = current_time + (remaining_time * 60)

          live_data << {
            table_id: table[:id],
            table_size: table[:size],
            status: status,
            start_time: start_time.strftime('%Y-%m-%d %H:%M:%S'),
            num_people: 0,
            elapsed_time: elapsed_time,
            est_finish_time: est_finish_time.strftime('%Y-%m-%d %H:%M:%S')
          }
        end
      else
        # Table is free
        live_data << {
          table_id: table[:id],
          table_size: table[:size],
          status: 'free',
          start_time: '',
          num_people: 0,
          elapsed_time: 0,
          est_finish_time: ''
        }
      end
    end

    # Write to CSV
    csv_path = Rails.root.join('data', 'tables_live.csv')
    CSV.open(csv_path, 'w') do |csv|
      # Header
      csv << ['table_id', 'table_size', 'status', 'start_time', 'num_people', 'elapsed_time', 'est_finish_time']

      live_data.each do |row|
        csv << [
          row[:table_id],
          row[:table_size],
          row[:status],
          row[:start_time],
          row[:num_people],
          row[:elapsed_time],
          row[:est_finish_time]
        ]
      end
    end

    puts "Generated #{live_data.count} live table records"
    puts "Occupancy: #{num_occupied}/#{all_tables.count} tables (#{(occupancy_rate * 100).round}%)"
    puts "Saved to #{csv_path}"
  end
end
