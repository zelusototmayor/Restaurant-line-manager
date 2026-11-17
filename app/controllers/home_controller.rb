class HomeController < ApplicationController
  def index
    @table_manager = TableManager.new
    @queue_manager = QueueManager.new
    @calculator = EtaCalculator.new(@table_manager)
    @stats = @calculator.restaurant_stats
    @waiting_parties = @queue_manager.waiting_parties
  end
end
