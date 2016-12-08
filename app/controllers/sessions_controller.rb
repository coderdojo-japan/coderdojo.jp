class SessionsController < ApplicationController
  def create
    if valid_credentials?(params[:login], params[:password])
      session[:user] = params[:login]
      redirect_to scrivito_path(Obj.root)
    else
      flash[:alert] = "The credentials you provided are invalid"
      redirect_to scrivito_path(LoginPage.instance)
    end
  end

  def destroy
    session[:user] = nil
    redirect_to scrivito_path(Obj.root)
  end

  private

  def valid_credentials?(login, password)
    login == 'login' && password == 'password'
  end

end
