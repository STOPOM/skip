# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

class PlatformController < ApplicationController
  layout 'not_logged_in'
  skip_before_filter :sso, :login_required, :prepare_session
  skip_before_filter :verify_authenticity_token, :only => :reset_openid
  skip_after_filter  :remove_message

  before_filter :require_not_login, :except => [:logout]
  protect_from_forgery :except => [:login]

  def index
    response.headers['X-XRDS-Location'] = formatted_server_url(:format => :xrds, :protocol => scheme)
    img_files = Dir.glob(File.join(RAILS_ROOT, "public", "custom", "images", "titles", "background*.{jpg,png,jpeg}"))
    @img_name = File.join("titles", File.basename(img_files[rand(img_files.size)]))
  end

  def require_login
  end

  # ログイン処理（トップからと、require_loginからの両方からpostされる）
  # 認証後は、戻り先がある場合はそちらへ、なければデフォルトはSKIPへ遷移
  def login
    if using_open_id?
      login_with_open_id
    else
<<<<<<< HEAD:app/controllers/platform_controller.rb
      login_with_password
=======
      logout_killing_session!
      if params[:login] and @current_user = User.auth(params[:login][:key], params[:login][:password])
        session[:user_code] = @current_user.code
        session[:auth_session_token] = @current_user.update_auth_session_token!
        handle_remember_cookie!(params[:login_save] == 'true')

        redirect_to_back_or_root
      else
        flash[:auth_fail_message] ||={ "message" => _("Log in failed."), "detail" => _("Refer to the contact information shown at the bottom of the screen to report the error.")}
        if request.env['HTTP_REFERER']
          redirect_to :back
        else
          redirect_to :action => :index
        end
      end
>>>>>>> for_i18n:app/controllers/platform_controller.rb
    end
  end

  # ログアウト
  def logout
    logout_killing_session!
    notice = _('You are now logged out.')
    notice = notice + "<br>" + _('You had been retired.') unless params[:message].blank?
    flash[:notice] = notice

    redirect_to login_mode?(:fixed_rp) ? "#{SkipEmbedded::InitialSettings['fixed_op_url']}logout" : {:action => "index"}
  end

  def forgot_password
    unless enable_forgot_password?
      render_404 and return
    end
    return unless request.post?
    email = params[:email]
<<<<<<< HEAD:app/controllers/platform_controller.rb
    if email.blank?
      flash.now[:error] = _('メールアドレスは必須です。')
      return
    end
    if @user = User.find_by_email(email)
      if @user.active?
        @user.issue_reset_auth_token
        @user.save_without_validation!
        UserMailer.deliver_sent_forgot_password(email, reset_password_url(@user.reset_auth_token))
        flash[:notice] = _("%{function}のためのURLを記載したメールを%{email}宛てに送信しました。") % {:email => email, :function => _('パスワードリセット')}
        redirect_to :controller => '/platform'
      else
        flash.now[:error] = _('入力された%{email}のユーザは、利用開始されていません。利用開始してください。') % {:email => email}
      end
    else
      flash.now[:error] = _("入力された%{email}というメールアドレスは登録されていません。") % {:email => email}
=======
    if @user_profile = UserProfile.find_by_email(email)
      user = @user_profile.user
      user.forgot_password
      user.save!
      UserMailer.deliver_sent_forgot_password(email, reset_password_url(user.password_reset_token))
      flash[:notice] = _("An email contains the URL for resetting the password has been sent to %s.") % email
      redirect_to :controller => '/platform'
    else
      flash[:error] = _("Entered email address %s has not been registered in the site.") % email
      render :layout => 'not_logged_in'
>>>>>>> for_i18n:app/controllers/platform_controller.rb
    end
  end

  def reset_password
    if @user = User.find_by_reset_auth_token(params[:code])
      if Time.now <= @user.reset_auth_token_expires_at
        return unless request.post?
        @user.crypted_password = nil
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
        if @user.save
<<<<<<< HEAD:app/controllers/platform_controller.rb
          flash[:notice] = _("%{function}が完了しました。")%{:function => _('パスワードリセット')}
          redirect_to :controller => '/platform'
        else
          flash.now[:error] = _("%{function}に失敗しました。")%{:function => _('パスワードリセット')}
        end
      else
        flash[:error] = _("%{function}のためのURLの有効期限が過ぎています。")%{:function => _('パスワードリセット')}
        redirect_to :controller => '/platform'
      end
    else
      flash[:error] = _("%{function}のためのURLが不正です。再度お試し頂くか、システム管理者にお問い合わせ下さい。")%{:function => _('パスワードリセット')}
=======
          @user.reset_password
          flash[:notice] = _("Password was successfully reset.")
          redirect_to :controller => '/platform'
        else
          flash[:error] = _("Failed to reset password.")
          render :layout => 'not_logged_in'
        end
      else
        flash[:error] = _("The URL for resetting password has already expired.")
        redirect_to :controller => '/platform'
      end
    else
      flash[:error] = _("Invalid password reset URL. Try again or contact system administrator.")
>>>>>>> for_i18n:app/controllers/platform_controller.rb
      redirect_to :controller => '/platform'
    end
  end

  def activate
    unless enable_activate?
      flash[:error] = _('%{function}は現在利用することが出来ません。') % {:function => '利用開始通知'}
      return redirect_to(:controller => '/platform')
    end
    return unless request.post?
    email = params[:email]
<<<<<<< HEAD:app/controllers/platform_controller.rb
    if email.blank?
      flash.now[:error] = _('メールアドレスは必須です。')
      return
    end
    if @user = User.find_by_email(email)
      if  @user.unused?
        @user.issue_activation_code
        @user.save_without_validation!
        UserMailer.deliver_sent_activate(email, signup_url(@user.activation_token))
        flash[:notice] = _("ユーザ登録のためのURLを記載したメールを%{email}宛てに送信しました。") % {:email => email}
        redirect_to :controller => '/platform'
      else
        flash[:error] = _("メールアドレスが%{email}のユーザは既に利用を開始しています。") % {:email => email}
      end
    else
      flash.now[:error] = _("入力された%{email}というメールアドレスは登録されていません。") % {:email => email}
    end
  end

  def signup
    unless enable_signup?
      flash[:error] = _('%{function}は現在利用することが出来ません。') % {:function => '利用登録'}
      return redirect_to(:controller => '/platform')
    end
    if @user = User.find_by_activation_token(params[:code])
      if @user.within_time_limit_of_activation_token?
        self.current_user = @user
        return redirect_to(:controller => :portal)
      else
        flash[:error] = _("ユーザ登録のためのURLの有効期限が過ぎています。")
        redirect_to :controller => '/platform'
      end
    else
      flash[:error] = _("ユーザ登録のためのURLが不正です。再度お試し頂くか、システム管理者にお問い合わせ下さい。")
=======
    if @user_profile = UserProfile.find_by_email(email)
      login_id = @user_profile.user.code
      UserMailer.deliver_sent_forgot_login_id(email, login_id)
      flash[:notice] = _("An email containing your login id is sent to %s.") % email
>>>>>>> for_i18n:app/controllers/platform_controller.rb
      redirect_to :controller => '/platform'
    end
  end

  def forgot_openid
    unless enable_forgot_openid?
      render_404 and return
    end
    return unless request.post?
    email = params[:email]
    if email.blank?
      flash.now[:error] = _('メールアドレスは必須です。')
      return
    end
    if user = User.find_by_email(email)
      if user.active?
        user.issue_reset_auth_token
        user.save_without_validation!
        UserMailer.deliver_sent_forgot_openid(email, reset_openid_url(user.reset_auth_token))
        flash[:notice] = _("OpenID URLを再設定するためのURLを記載したメールを%{email}宛に送信しました。") % {:email => email}
        redirect_to :controller => "/platform"
      else
        flash.now[:error] = _('入力された%{email}のユーザは、利用開始されていません。利用開始してください。') % {:email => email}
      end
    else
      flash.now[:error] = _("入力された%{email}というメールアドレスは登録されていません。") % {:email => email}
    end
  end

  def reset_openid
    if user = User.find_by_reset_auth_token(params[:code])
      if Time.now <= user.reset_auth_token_expires_at
        @identifier = user.openid_identifiers.first || user.openid_identifiers.build
        if using_open_id?
          begin
            authenticate_with_open_id do |result, identity_url|
              if result.successful?
                @identifier.url = identity_url
                if @identifier.save
                  user.determination_reset_auth_token
                  flash[:notice] = _("%{function}が完了しました。")%{:function => _('OpenID URLの再設定')} + _("設定したURLを入力してログインしてください。")
                  redirect_to :action => :index
                end
              else
                flash.now[:error] = _("OpenIDの処理の中でキャンセルされたか、失敗しました。")
              end
            end
          rescue OpenIdAuthentication::InvalidOpenId
            flash.now[:error] = _("OpenIDの形式が正しくありません。")
          end
        end
      else
        flash[:error] = _("%{function}のためのURLの有効期限が過ぎています。")%{:function => _('OpenID URLの再設定')}
        redirect_to :controller => '/platform'
      end
    else
<<<<<<< HEAD:app/controllers/platform_controller.rb
      flash[:error] = _("%{function}のためのURLが不正です。再度お試し頂くか、システム管理者にお問い合わせ下さい。")%{:function => _('OpenID URLの再設定')}
      redirect_to :controller => '/platform'
=======
      flash[:error] = _("Entered email address %s has not been registered in the site.") % email
      render :layout => 'not_logged_in'
>>>>>>> for_i18n:app/controllers/platform_controller.rb
    end
  end

  private
  def require_not_login
    if current_user
      unless current_user.unused?
        redirect_to_return_to_or_root
      else
        redirect_to :controller => :portal, :action => :index
      end
    end
  end

  def login_with_open_id
    session[:return_to] = params[:return_to] if !params[:return_to].blank? and params[:open_id_complete].blank?
    begin
      authenticate_with_open_id( params[:openid_url],
                                 :required => SkipEmbedded::InitialSettings["ax_fetchrequest"].values.flatten) do |result, identity_url, registration|
        if result.successful?
          logger.info("[Login successful with OpenId] \"OpenId\" => #{identity_url}")
          unless identifier = OpenidIdentifier.find_by_url(identity_url)
            create_user_from(identity_url, registration)
          else
            return_to = session[:return_to]
            reset_session

            self.current_user = identifier.user_with_unused
            redirect_to_return_to_or_root(return_to)
          end
        else
          logger.info("[Login failed with OpenId] \"OpenId\" => #{identity_url}")
          set_error_message_form_result_and_redirect(result)
        end
      end
    rescue OpenIdAuthentication::InvalidOpenId
      logger.info("[Login failed with OpenId] \"OpenId is invalid\"")
      flash[:error] = _("OpenIDの形式が正しくありません。")
      redirect_to :action => :index
    end
  end

  def create_user_from(identity_url, registration)
    if login_mode?(:fixed_rp) and identity_url.include?(SkipEmbedded::InitialSettings['fixed_op_url'])
      user = User.create_with_identity_url(identity_url, create_user_params(registration))
      if user.valid?
        reset_session
        self.current_user = user

        redirect_to :controller => :portal
      else
        set_error_message_from_user_and_redirect(user)
      end
    elsif login_mode?(:free_rp)
      session[:identity_url] = identity_url

      redirect_to :controller => :portal, :action => :index
    else
      set_error_message_not_create_new_user_and_redirect
    end
  end

  def redirect_to_return_to_or_root(return_to = params[:return_to])
    return_to = return_to ? URI.encode(return_to) : nil
    redirect_to (return_to and !return_to.empty?) ? return_to : root_url
  end

  def create_user_params(fetched)
    returning({}) do |res|
      SkipEmbedded::InitialSettings["ax_fetchrequest"].each do |k, vs|
        fetched.each{|fk, (fv,_)| res[k] = fv if !fv.blank? && vs == fk }
      end
    end
  end

  def set_error_message_form_result_and_redirect(result)
    error_messages = {
<<<<<<< HEAD:app/controllers/platform_controller.rb
      :missing      => _("OpenIDサーバーが見つかりませんでした。正しいOpenID URLを入力してください。"),
      :canceled     => _("キャンセルされました。このサーバへの認証を確認してください"),
      :failed       => _("OpenIDの認証に失敗しました。"),
      :setup_needed => _("内部エラーが発生しました。管理者に連絡してください。")
=======
      :missing      => [_("OpenID server not found."), _("Please provide a correct OpenID URL.")] ,
      :canceled     => [_("Operation cancelled."), _("Please confirm to authenticate with the server.") ],
      :failed       => [_("Authentication failed."), "" ],
      :setup_needed => [_("Internal error(s) occured."), _("Contact administrator.") ]
>>>>>>> for_i18n:app/controllers/platform_controller.rb
    }
    set_error_message_and_redirect error_messages[result.instance_variable_get(:@code)]
  end

  def set_error_message_from_user_and_redirect(user)
<<<<<<< HEAD:app/controllers/platform_controller.rb
    set_error_message_and_redirect _("ユーザの登録に失敗しました。管理者に連絡してください。<br/>%{msg}")%{:msg => user.errors.full_messages}
  end

  def set_error_message_not_create_new_user_and_redirect
    set_error_message_and_redirect _("そのOpenIDは、登録されていません。ログイン後管理画面でOpenID URLを登録後ログインしてください。")
=======
    set_error_message_and_redirect [_("Failed to register user."), _("Contact administrator.<br/>%{msg}")%{:msg => user.errors.full_messages}], :action => :index
  end

  def set_error_message_not_create_new_user_and_redirect
    set_error_message_and_redirect [_("OpenID had not been registered."), _("Log in, register the OpenID URL in the administration screen then log in again.")], :action => :index
>>>>>>> for_i18n:app/controllers/platform_controller.rb
  end

  def set_error_message_and_redirect(message)
    flash[:error] = message
    redirect_to({:action => :index})
  end

  def login_with_password
    logout_killing_session!([:request_token])
    if params[:login] and user = User.auth(params[:login][:key], params[:login][:password], params[:login][:keyphrase])
      if user.locked?
        logger.info(user.to_s_log('[Login failed with password]'))
        flash[:error] = _("入力されたログインIDのユーザのパスワードが現在無効になっています。パスワードの再設定を行って下さい。")
        redirect_to(request.env['HTTP_REFERER'] ? :back : login_url)
      else
        unless user.within_time_limit_of_password?
          logger.info(user.to_s_log('[Login failed with password]'))
          flash[:error] = _("パスワードの有効期限を過ぎています。パスワードの再設定を行って下さい。")
          redirect_to(request.env['HTTP_REFERER'] ? :back : login_url)
        else
          self.current_user = user
          logger.info(current_user.to_s_log('[Login successful with password]'))
          handle_remember_cookie!(params[:login_save] == 'true')
          redirect_to_return_to_or_root
        end
      end
    else
      if params[:login]
        logger.info(User.to_s_log('[Login failed with password]', params[:login][:key]))
      else
        logger.info('[Login failed for parameter is not specified]')
      end
      flash[:error] = _("ログインに失敗しました。")
      redirect_to(request.env['HTTP_REFERER'] ? :back : login_url)
    end
  end
end
