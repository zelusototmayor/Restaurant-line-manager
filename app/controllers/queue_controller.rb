class QueueController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @queue_manager = QueueManager.new
    @waiting_parties = @queue_manager.waiting_parties
    @table_manager = TableManager.new
    @stats = EtaCalculator.new(@table_manager).restaurant_stats

    respond_to do |format|
      format.html
      format.json do
        render json: {
          waiting_parties: @waiting_parties,
          restaurant_stats: @stats,
          total_in_queue: @waiting_parties.count,
          total_people_waiting: @waiting_parties.sum { |p| p[:party_size] }
        }
      end
    end
  end

  def add
    party_size = params[:party_size].to_i

    queue_manager = QueueManager.new
    entry = queue_manager.add_party(party_size)

    position = queue_manager.position(entry[:queue_number])

    respond_to do |format|
      format.html do
        @entry = entry
        @position = position
        @queue_manager = queue_manager
      end
      format.json do
        render json: {
          success: true,
          queue_number: entry[:queue_number],
          position: position,
          party_size: entry[:party_size],
          party_label: entry[:party_label],
          eta_min: entry[:eta_min],
          eta_max: entry[:eta_max],
          message: "You are ##{position} in line"
        }
      end
    end
  end

  def remove
    queue_number = params[:id].to_i

    queue_manager = QueueManager.new
    queue_manager.remove_party(queue_number)

    respond_to do |format|
      format.html do
        flash[:notice] = "Party ##{queue_number} removed from queue"
        redirect_to queue_path
      end
      format.json do
        render json: {
          success: true,
          message: "Party removed from queue"
        }
      end
    end
  end

  def clear
    queue_manager = QueueManager.new
    queue_manager.clear_queue

    respond_to do |format|
      format.html do
        flash[:notice] = "Queue cleared"
        redirect_to queue_path
      end
      format.json do
        render json: {
          success: true,
          message: "Queue cleared"
        }
      end
    end
  end
end
