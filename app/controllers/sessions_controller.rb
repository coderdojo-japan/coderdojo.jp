# -*- coding: utf-8 -*-
class SessionsController < ApplicationController
  before_filter :logged_in?, only: [:create, :destroy]

  def create
    if valid_credentials?(params[:email], params[:password])
      session[:user] = params[:email]
      redirect_to sotechsha_path
    else
      flash[:alert] = "メールアドレスとパスワードの組み合わせが間違っています ><💦 "
      redirect_to scrivito_path(LoginPage.instance)
    end
  end

  def destroy
    session[:user] = nil
    redirect_to sotechsha_path
  end

  private

  def valid_credentials?(email, password)
    email == ENV['SCRIVITO_EMAIL'] && password == ENV["SCRIVITO_PASSWORD"]
  end

end
