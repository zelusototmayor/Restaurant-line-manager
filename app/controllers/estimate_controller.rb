class EstimateController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    party_size = params[:party_size].to_i

    calculator = EtaCalculator.new
    result = calculator.calculate(party_size)

    respond_to do |format|
      format.json { render json: result }
      format.html do
        @result = result
        @party_size = party_size
      end
    end
  end
end
