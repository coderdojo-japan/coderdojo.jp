# -*- coding: utf-8 -*-
class SessionsController < CmsController
  before_action :logged_in_user, only: [:destroy]

  def create
    if valid_credentials?(params[:email], params[:password])
      session[:user] = params[:email]
      redirect_back_or scrivito_path(Obj.root)
    else
      flash[:alert] = "メールアドレスとパスワードの組み合わせが間違っています ><💦 "
      redirect_to scrivito_path(LoginPage.instance)
    end
  end

  def destroy
    flash[:success] = "ログアウトしました 🏃💨🚪"
    session[:user] = nil
    redirect_back_or scrivito_path(Obj.root)
  end

  private

  def valid_credentials?(email, password)
    email == ENV['SCRIVITO_EMAIL'] && password == ENV["SCRIVITO_PASSWORD"]
  end

  def logged_in_user
    unless logged_in?
      flash[:danger] = "ログインをお願いします🙇🏻"
      redirect_to scrivito_path(Obj.root)
    end
  end
end
