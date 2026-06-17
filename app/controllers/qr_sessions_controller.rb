class QrSessionsController < ApplicationController
  before_action :authenticate_user!, only: :new
  before_action :authenticate_user_by_qr_code!, only: :qr_sign_in

  # qr_sign_in
  def new
    token = current_user.generate_token_for(:qr_sign_in)
    qr_code = RQRCode::QRCode.new("https://104jq.hatchboxapp.com/qr_sessions?token=#{token}")
    @svg = qr_code.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 4,
      standalone: true,
      use_path: true
    )
  end

  def qr_sign_in
    if user_signed_in?
      redirect_to root_path, notice: "You have successfully transferred your session!"
    else
      redirect_to root_path, alert: "Invalid token."
    end
  end

  private

  def authenticate_user_by_qr_code!
    @user = User.find_by_token_for(:qr_sign_in, params[:token])
    sign_in @user
  end
end
