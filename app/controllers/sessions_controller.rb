class SessionsController < ApplicationController

  before_action :check_user, only: [:two_factor_auth, :new, :resend_otp_to_phone, :resend_otp_to_email]
  skip_before_action :verify_authenticity_token, only: [:create_external, :show_external]

  def new
  end

  def create_external
    begin
      auth_params = params.require(:auth).permit :phone, :password, :device_id, :device_name
      user = User.find_by phone: auth_params[:phone]
      unless user
        head :not_found
        return
      end
      if user.authenticate auth_params[:password]
        users_device = user.external_devices.find{|d| d.device_id == auth_params[:device_id]}
        if users_device && users_device.registered
          secret_key = Rails.application.secrets.secret_key_base
          payload = {sub: user.id, iat: Time.now.to_i, iss: users_device.device_id}
          token = JWT.encode payload, secret_key, 'HS256'
          database_key = (user.created_at.to_f * 1000000).to_i
          render json: { jwt: token, user: user.id , key: database_key}, status: :created
        else
          unless users_device
            new_device = ExternalDevice.new
            new_device.device_id = auth_params[:device_id]
            new_device.name = auth_params[:device_name]
            new_device.user = user
            new_device.save
          end
          render json: { user: user.id }
        end
      else
        head :not_found
      end
    rescue => e
      render json: { error: e, secret_key_found: !!secret_key, payload_found: !!payload, token_found: !!token}
    end
  end

  def show_external
    full_params = params.require(:session).permit :user_id, :device_id
    begin
    user = User.find(full_params['user_id']) if full_params['user_id'] != -1
    if user.nil?# && user.devices.include?(full_params['device_id'])
      head :not_found
      return
    end
    database_key = (user.created_at.to_f * 1000000).to_i
    render json: { key: database_key }
    rescue => e
    render json: { error: e }
    end
  end

  def two_factor_auth
    @user = User.find_by(phone: params[:session][:phone])
    if @user && @user.authenticate(params[:session][:password])
      phone = params[:session][:phone]
      otp_code = @user.otp_code
      session[:temp_user] = @user.id
      @ticket =  send_otp_on_phone("+91#{phone}", otp_code)
      #   flash.now['info'] = "A short login code has been sent to your phone (#{phone})"
      # elsif send_otp_via_mail(@user, otp_code)
      #   flash.now['info'] = "A short login code has been sent to your email (#{@user.email})."
      # else
      #   flash.now['error'] = "We were not able to send the login code to #{phone} or email #{@user.email}!"
      # end
    else
      flash.now['error'] = 'Phone number or password is not correct'
      render 'new'
    end
  end

  def resend_otp_to_phone
    logger.debug('resend otp')
    if session[:temp_user]
      if user = User.find_by(id: session[:temp_user])
        render json: { ticket: send_otp_on_phone("+91#{user.phone}", user.otp_code) }
      else
        # temp user doesn't exist so go back to square 1
        redirect_to login_path
      end
    else
      # no temp user so we need the login credentials
      redirect_to login_path
    end
  end

  def resend_otp_to_email
    logger.debug('resend otp email')
    if session[:temp_user]
      user = User.find_by(id: session[:temp_user])
      if user and send_otp_via_mail(user, user.otp_code)
        #success
        render json: { success: true }
      else
        #fail
        render json: { success: false }
      end
    else
      # no temp user so we need the login credentials
      redirect_to login_path
    end
  end

  def poll
    ticket = params[:ticket]
    logger.debug("polling for #{ticket}")
    render json: BcsSms.poll(ticket.to_i)
  end

  def create
    # don't need to create a session if we're already logged in
    if logged_in?
      logger.debug 'already logged in!'
      redirect_to root_path and return
    end
    # if user password hasn't been authenticated yet then go back to login
    if session[:temp_user].blank?
      logger.debug 'user password not yet authenticated'
      redirect_to login_path and return
    end
    user = User.find session[:temp_user]

    if user and user.authenticate_otp(params[:session][:otp_code], drift: 300)
        session[:temp_user] = nil
        log_in user
        remember user
        # if the user's password is "password" they should change it
        if user.authenticate('password')
          flash['info'] = 'Welcome to Last Command Initiative Reporter.' +
              ' Please make a new password. It should be something another person could not guess.' +
              ' Type it here two times and click \'update\'.'
          redirect_to edit_user_path(user)
        else
          redirect_back_or root_path and return
        end
    else
      @user = user
      flash.now['error'] = 'Login code incorrect or expired.'
      render 'two_factor_auth'
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to login_url
  end

  private

  def send_otp_on_phone(phone_number, otp_code)
    begin
      logger.debug("sending otp to phone: #{phone_number}, otp: #{otp_code}")
      wait_ticket = BcsSms.send_otp(phone_number, otp_code)
      logger.debug("waiting #{wait_ticket}")
      return wait_ticket
    rescue => e
      logger.error("couldn't send OTP to phone: #{e.message}")
      return false
    end
  end

  def send_otp_via_mail(user, otp_code)
    if user.email.present? && user.email_confirmed?
      UserMailer.user_otp_code(user, otp_code).deliver_now
      return true
    else
      return false
    end
  end

  def check_user
     redirect_to root_path if logged_in?
  end
end
