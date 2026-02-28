class ApplicationController < ActionController::Base
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present? && current_user.is_active?
  end

  def require_login!
    redirect_to login_path, alert: "로그인이 필요합니다." unless logged_in?
  end

  def require_host!
    return if logged_in? && (current_user.host? || current_user.admin?)

    redirect_to root_path, alert: "호스트 권한이 필요합니다."
  end

  def require_guest!
    return if logged_in? && current_user.guest?

    redirect_to root_path, alert: "게스트 계정만 사용할 수 있습니다."
  end
end
