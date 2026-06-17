class SessionsController < ApplicationController
  def new
  end

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      sign_in user
      redirect_to root_path, notice: "You have signed in."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to root_path, notice: "You have been logged out."
  end
end
