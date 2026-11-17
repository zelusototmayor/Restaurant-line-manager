namespace :data do
  desc "Generate randomized initial queue (0-7 parties already waiting)"
  task generate_queue: :environment do
    puts "Generating randomized queue..."

    # Clear existing queue
    queue_manager = QueueManager.new
    queue_manager.clear_queue

    # Random number of parties already waiting (0-7)
    num_parties = rand(0..7)

    if num_parties == 0
      puts "Queue is empty - next person will be first!"
      return
    end

    # Generate anonymous demo parties
    num_parties.times do |i|
      # Random party size (weighted towards smaller groups)
      party_size = [2, 2, 2, 3, 3, 4, 4, 4, 5, 6, 8].sample

      # Add to queue
      entry = queue_manager.add_party(party_size)

      puts "  Added: #{entry[:party_label]} (Party of #{party_size})"
    end

    puts "\nQueue generated with #{num_parties} #{num_parties == 1 ? 'party' : 'parties'} waiting"

    # Show summary
    waiting = queue_manager.waiting_parties
    if waiting.any?
      puts "\nCurrent Queue:"
      waiting.each_with_index do |entry, idx|
        puts "  ##{idx + 1}: #{entry[:party_label]} - Party of #{entry[:party_size]} - Wait: #{entry[:eta_min]}-#{entry[:eta_max]} min"
      end

      total_people = waiting.sum { |p| p[:party_size] }
      puts "\nTotal: #{waiting.count} parties, #{total_people} people waiting"
    end
  end
end
