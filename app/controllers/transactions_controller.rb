require "net/http"

class TransactionsController < RageController::API
  rescue_from SocketError do |_|
    render json: { message: "error" }, status: 500
  end

  def create
    case Transaction.new(params[:id], params[:valor], params[:tipo], params[:descricao]).create
    in [:success, result]
      render json: result
    in [:failure, :client_not_found]
      head :not_found
    in [:failure, _]
      head :unprocessable_entity
    end
  end
end
