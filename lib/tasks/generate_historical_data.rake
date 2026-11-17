require 'csv'
require 'json'

namespace :data do
  desc "Generate 30 days of historical restaurant data"
  task generate_historical: :environment do
    puts "Generating historical data..."

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

    # Generate data for 30 days
    end_date = Date.today
    start_date = end_date - 30.days

    historical_data = []

    (start_date..end_date).each do |date|
      # Skip Mondays (closed)
      next if date.wday == 1

      # Determine session count (weekends busier)
      is_weekend = [0, 6].include?(date.wday)

      # Lunch session (11:30-15:30)
      lunch_tables_used = (all_tables.count * (is_weekend ? 0.7 : 0.5)).to_i
      historical_data += generate_session_data(date, all_tables.sample(lunch_tables_used), 11.5, 15.5, 'lunch')

      # Dinner session (19:00-23:00)
      dinner_tables_used = (all_tables.count * (is_weekend ? 0.9 : 0.7)).to_i
      historical_data += generate_session_data(date, all_tables.sample(dinner_tables_used), 19.0, 23.0, 'dinner')
    end

    # Write to CSV
    csv_path = Rails.root.join('data', 'tables_history.csv')
    CSV.open(csv_path, 'w') do |csv|
      # Header
      csv << ['date', 'table_id', 'party_size', 'start_time', 'finish_time', 'bill_printed_time',
              'num_dishes', 'num_mains', 'num_desserts', 'coffee', 'alcoholic_drinks',
              'num_alcoholic_drinks', 'last_order_time', 'duration']

      historical_data.each do |row|
        csv << row
      end
    end

    puts "Generated #{historical_data.count} historical records"
    puts "Saved to #{csv_path}"
  end

  private

  def generate_session_data(date, tables, start_hour, end_hour, session_type)
    data = []

    tables.each do |table|
      # Random party size (weighted towards smaller groups)
      party_size = [
        [1, 2, 2, 3, 3, 4, 4, 4, 5, 6, 7, 8, 9, 10].sample,
        table[:size]
      ].min

      # Random start time within session
      session_duration = end_hour - start_hour
      start_offset = rand * (session_duration - 2) # Leave room for table service
      start_time = date.to_time + (start_hour * 3600) + (start_offset * 3600)

      # Duration based on party size (45-120 minutes)
      base_duration = 45 + (party_size * 8) # Larger parties take longer
      duration = base_duration + rand(-15..20) # Add randomness
      duration = [duration, 120].min # Cap at 120 minutes

      finish_time = start_time + (duration * 60)

      # Bill printed 5-10 minutes before finish
      bill_offset = rand(5..10)
      bill_printed_time = finish_time - (bill_offset * 60)

      # Orders (scaled by party size)
      num_mains = party_size + rand(-1..1)
      num_mains = [num_mains, 1].max
      num_desserts = (party_size * 0.6).to_i + rand(0..1)
      num_dishes = num_mains + num_desserts + rand(0..3) # Appetizers/sides

      # Coffee (40% chance)
      coffee = rand < 0.4

      # Alcoholic drinks (60% at dinner, 30% at lunch)
      alcohol_chance = session_type == 'dinner' ? 0.6 : 0.3
      alcoholic_drinks = rand < alcohol_chance
      num_alcoholic_drinks = alcoholic_drinks ? rand(1..party_size * 2) : 0

      # Last order time (10-30 minutes before finish)
      last_order_offset = rand(10..30)
      last_order_time = finish_time - (last_order_offset * 60)

      data << [
        date.to_s,
        table[:id],
        party_size,
        start_time.strftime('%Y-%m-%d %H:%M:%S'),
        finish_time.strftime('%Y-%m-%d %H:%M:%S'),
        bill_printed_time.strftime('%Y-%m-%d %H:%M:%S'),
        num_dishes,
        num_mains,
        num_desserts,
        coffee,
        alcoholic_drinks,
        num_alcoholic_drinks,
        last_order_time.strftime('%Y-%m-%d %H:%M:%S'),
        duration
      ]
    end

    data
  end
end
