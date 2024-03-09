require "net/http"

class BankStatementsController < RageController::API
  rescue_from SocketError do |_|
    render json: { message: "error" }, status: 500
  end

  def show
    if result = Statement.new(params[:id]).show
      render json: result
    else
      head :not_found
    end
  end
end
