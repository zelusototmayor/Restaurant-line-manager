class LiveController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:reset]

  def index
    table_manager = TableManager.new
    calculator = EtaCalculator.new(table_manager)

    @tables = table_manager.live_tables
    @stats = calculator.restaurant_stats
    @tables_by_status = {
      free: table_manager.free_tables,
      occupied: table_manager.tables_by_status('occupied'),
      bill_printed: table_manager.tables_by_status('bill_printed'),
      cleaning: table_manager.tables_by_status('cleaning')
    }

    respond_to do |format|
      format.html
      format.json { render json: { tables: @tables, stats: @stats } }
    end
  end

  def reset
    # Regenerate live data and queue
    system('rails data:generate_live')
    system('rails data:generate_queue')

    respond_to do |format|
      format.html do
        flash[:notice] = "Live data and queue regenerated successfully!"
        redirect_to live_path
      end
      format.json { render json: { success: true, message: "Live data and queue regenerated" } }
    end
  end
end
