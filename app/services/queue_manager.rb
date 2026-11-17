require 'csv'

class QueueManager
  attr_reader :queue

  def initialize
    load_queue
  end

  # Add a party to the queue
  def add_party(party_size)
    # Generate queue number
    queue_number = next_queue_number

    # Calculate ETA based on current queue and restaurant state
    eta_result = calculate_eta_for_new_party(party_size)

    new_entry = {
      queue_number: queue_number,
      party_size: party_size,
      party_label: "Party #{queue_number}",
      added_at: Time.now,
      eta_min: eta_result[:eta_min],
      eta_max: eta_result[:eta_max],
      status: 'waiting'
    }

    @queue << new_entry
    save_queue

    new_entry
  end

  # Get all waiting parties
  def waiting_parties
    @queue.select { |entry| entry[:status] == 'waiting' }
  end

  # Get queue position for a queue number
  def position(queue_number)
    waiting_parties.find_index { |entry| entry[:queue_number] == queue_number } + 1
  end

  # Remove a party from queue (when seated or cancelled)
  def remove_party(queue_number)
    @queue.reject! { |entry| entry[:queue_number] == queue_number }
    save_queue
  end

  # Mark party as seated
  def mark_seated(queue_number)
    entry = @queue.find { |e| e[:queue_number] == queue_number }
    entry[:status] = 'seated' if entry
    save_queue
  end

  # Get total people waiting ahead of a position
  def people_ahead(position)
    waiting_parties[0...position].sum { |entry| entry[:party_size] }
  end

  # Clear entire queue
  def clear_queue
    @queue = []
    save_queue
  end

  # Recalculate all ETAs (useful when restaurant state changes)
  def recalculate_all_etas
    table_manager = TableManager.new
    eta_calculator = EtaCalculator.new(table_manager)

    cumulative_wait = 0

    waiting_parties.each_with_index do |entry, index|
      if index == 0
        # First in queue: base ETA from current restaurant state
        base_eta = eta_calculator.calculate(entry[:party_size])
        entry[:eta_min] = base_eta[:eta_min]
        entry[:eta_max] = base_eta[:eta_max]
        cumulative_wait = base_eta[:eta_max]
      else
        # Subsequent parties: add time for parties ahead
        prev_party = waiting_parties[index - 1]
        additional_wait = estimate_service_time(prev_party[:party_size])

        entry[:eta_min] = cumulative_wait + 5
        entry[:eta_max] = cumulative_wait + additional_wait
        cumulative_wait = entry[:eta_max]
      end
    end

    save_queue
  end

  private

  def load_queue
    csv_path = Rails.root.join('data', 'queue.csv')

    @queue = []

    if File.exist?(csv_path)
      CSV.foreach(csv_path, headers: true, header_converters: :symbol) do |row|
        @queue << {
          queue_number: row[:queue_number].to_i,
          party_size: row[:party_size].to_i,
          party_label: "Party #{row[:queue_number].to_i}",
          added_at: Time.parse(row[:added_at]),
          eta_min: row[:eta_min].to_i,
          eta_max: row[:eta_max].to_i,
          status: row[:status]
        }
      end
    end
  end

  def save_queue
    csv_path = Rails.root.join('data', 'queue.csv')

    CSV.open(csv_path, 'w') do |csv|
      csv << ['queue_number', 'party_size', 'party_label', 'added_at', 'eta_min', 'eta_max', 'status']

      @queue.each do |entry|
        csv << [
          entry[:queue_number],
          entry[:party_size],
          entry[:party_label],
          entry[:added_at].strftime('%Y-%m-%d %H:%M:%S'),
          entry[:eta_min],
          entry[:eta_max],
          entry[:status]
        ]
      end
    end
  end

  def next_queue_number
    return 1 if @queue.empty?
    @queue.map { |e| e[:queue_number] }.max + 1
  end

  def calculate_eta_for_new_party(party_size)
    table_manager = TableManager.new
    eta_calculator = EtaCalculator.new(table_manager)

    # If first in queue, get base ETA from restaurant
    if waiting_parties.empty?
      base_eta = eta_calculator.calculate(party_size)
      return {
        eta_min: base_eta[:eta_min],
        eta_max: base_eta[:eta_max]
      }
    end

    # Calculate cumulative wait based on all parties ahead
    cumulative_wait = 0

    waiting_parties.each do |entry|
      service_time = estimate_service_time(entry[:party_size])
      cumulative_wait += service_time
    end

    # Add base wait time for current restaurant state
    base_eta = eta_calculator.calculate(party_size)

    {
      eta_min: cumulative_wait + base_eta[:eta_min],
      eta_max: cumulative_wait + base_eta[:eta_max]
    }
  end

  # Estimate how long it takes to seat and start serving a party
  def estimate_service_time(party_size)
    # Larger parties take longer to seat and get started
    base_time = 8 # Base 8 minutes per party
    size_factor = party_size * 2 # 2 minutes per person

    base_time + size_factor
  end
end
