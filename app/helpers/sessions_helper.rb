module SessionsHelper
  def logged_in?
    session[:user].present?
  end

  def redirect_back_or(default)
    redirect_to(session[:original_url]||default)
  end

end
