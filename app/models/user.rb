class User < ActiveRecord::Base
  has_secure_password

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: REGEXP[:email],
                                                                                     message: "Invalid Format"}
  validates :password, length: { minimum: 6 }, allow_blank: true


  before_create :set_and_generate_verification_token
  after_commit :send_verification_mail, on: :create

  def valid_verification_token?
    Time.current <= verification_token_expire_at
  end

  def valid_forgot_password_token?
    Time.current <= forgot_password_expire_at
  end

  #FIXME_AB: This will be reimplemented as change_password
  def verify_forgot_password!
    self.forgot_password_token = nil
    self.forgot_password_expire_at = nil
    save!
  end

  def verify!
    self.verified_at = Time.current
    self.verification_token = nil
    self.verification_token_expire_at = nil
    save!
  end

  def set_forgot_password_token
    generate_token(:forgot_password_token)
    set_token_expiry(:forgot_password_expire_at)
    save!
  end

  def set_remember_token
    generate_token(:remember_token)
    save!
  end

  #FIXME_AB: clear_remember_token!
  def reset_remember_token!
    self.remember_token = nil
    save!
  end
  
  private

    def random_token
      SecureRandom.urlsafe_base64.to_s
    end

    def set_and_generate_verification_token
      generate_token(:verification_token)
      set_token_expiry(:verification_token_expire_at)
    end

    def set_token_expiry(column)
      #FIXME_AB: CONSTANTS["time_to_verify"].hours.from_now
      self[column] = (Time.current + CONSTANTS["time_to_verify"].hours)
    end

    def send_verification_mail
      UserNotifier.verification_mail(self).deliver
    end

    def generate_token(token_for)
      loop do
        token_value = random_token
        if !(User.exists?(token_for => token_value))
          self[token_for] = token_value
          break
        end
      end
    end

end