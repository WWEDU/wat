# -*- encoding : utf-8 -*-
class SessionsController < ApplicationController

  def new
  end

  # 1. Login if user found by authentication or could be created through auth
  # 2. Redirect to edit_user if email is invalid
  # 3. Redirect to root_url with notice
  def create
    auth = request.env["omniauth.auth"]
    user = User.find_or_create_with_omniauth(auth,current_user)

    if user && user.valid?
      
      session[:user_id] = user.id
      
      if user.email.present? && auth['provider'] !~ /identity/i
        user.email_confirmed_at ||= Time.now
        user.save!
        _send_notification = false
      else
        _send_notification = true
      end
      
      if user.email.blank? 
        redirect_to edit_user_path(user.id.to_s), :info => t(:please_enter_your_email_address)
      else
        unless user.email_confirmed?
          flash[:message] = t(:email_not_confirmed_yet, email: user.email, 
            confirm_link: dirty_link_to(I18n.t(:resend_confirmation_mail), resend_confirmation_mail_user_path(user))
          ).html_safe

          if _send_notification
            UserMailer.registration_confirmation(user).deliver
          end
        end
        signed_in_successfully
      end
    else
      if user
        flash[:message] = t(:create_a_local_user_first_and_connect, provider: auth[:provider].humanize).html_safe
      end
      redirect_to signin_path, :alert => t(:invalid_credentials_or_user_exists, user: user ? user.name : '')
    end
  end

  def destroy
    reset_session
    redirect_to root_url, :notice => t(:signed_out)
  end

  def failure
    redirect_to root_url, :alert => t(:authentication_error, error: params[:message].humanize)
  end

  def switch_language
    if Settings.multilanuage == true
      session[:locale] = params[:locale].to_sym
      cookies.permanent[:locale] = params[:locale].to_sym
      _msg = {:notice => t(:language_changed_to, :lang => t(params[:locale].to_sym))}
    else
      _msg = {:alert => t(:cannot_change_language)}
    end
    _path =  request.env['HTTP_REFERER'].present? ? :back : root_path
    redirect_to _path, _msg
  end

private
  def dirty_link_to(body,url)
    "<a href='#{url}'>#{body}</a>".html_safe
  end

  def signed_in_successfully
    #redirect_to root_url, :notice => 'OK'
    back_url = session[:login_for_request] || root_url
    back_url.gsub! /[\A"|"\Z]/,''
    redirect_to back_url, :notice => t(:signed_in)
    session[:login_for_request] = nil
  end
end
