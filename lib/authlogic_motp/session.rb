require 'digest/md5'
module AuthlogicMotp
  module Session
    def self.included(klass)
      klass.class_eval do
        extend Config
        include Methods
      end
    end
    
    module Config
      def motp_maxperiod(value = nil)
        rw_config(:motp_maxperiod_method, value, :motp_maxperiod)
      end
      alias_method :motp_maxperiod=, :motp_maxperiod
    end
    
    module Methods
      def self.included(klass)
        klass.class_eval do
          attr_accessor :otp_login
          attr_accessor :otp_password
          
          validate :validate_by_otp, :if => :authenticating_with_otp?
        end
      end
      
      def credentials
        if authenticating_with_otp?
          details = {}
          details[:otp_login] = send(login_field)
          details[:otp_password] = '<protected>'
          details
        else
          super
        end
      end
      
      def credentials=(value)
        super
        values = value.is_a?(Array) ? value : [value]
        hash = values.first.is_a?(Hash) ? values.first.with_indifferent_access : nil
        if !hash.nil?
          self.otp_login = hash[:otp_login] if hash.key?(:otp_login)
          self.otp_password = hash[:otp_password] if hash.key?(:otp_password)
        end
      end
      
      private
      def authenticating_with_otp?
        !otp_login.blank? || !otp_password.blank?
      end
      
      def motp_maxperiod
        self.class.motp_maxperiod
      end
      
      def find_by_otp_login_method
        self.class.find_by_login_method
      end
      
      def generalize_credentials_error_messages?
        self.class.generalize_credentials_error_messages
      end
      
      def add_general_credentials_error
        error_message =
        if self.class.generalize_credentials_error_messages.is_a? String
          self.class.generalize_credentials_error_messages
        else
          "Login credentials are not valid"
        end
        errors.add(:base, I18n.t('error_messages.general_credentials_error', :default => error_message))
      end
      
      def validate_by_otp
        errors.add(:login, I18n.t('error_messages.login_blank', :default => 'cannot be blank')) if otp_login.blank?
        errors.add(:password, I18n.t('error_messages.password_blank', :default => 'cannot be blank')) if otp_password.blank?
        return if errors.count > 0
        
        self.attempted_record = klass.send(find_by_otp_login_method, otp_login)
        if attempted_record.blank?
          generalize_credentials_error_messages? ?
            add_general_credentials_error :
            errors.add(:login, I18n.t('error_messages.login_not_found', :default => "does not exist"))
          return
        else
          # don't allow otp that have been successfully used recently in the past
          # even if it is within the legal time frame (otp does mean _one_ time password!)
          old_otp = attempted_record.otp_cache.split(',') unless attempted_record.otp_cache.blank?
          old_otp ||= []
          otp_hash = Digest::MD5.hexdigest(otp_password)
          if old_otp.include?(otp_hash)
            generalize_credentials_error_messages? ?
              add_general_credentials_error :
              errors.add(:password, I18n.t('error_messages.password_invalid', :default => "is invalid"))
            return
          end
          
          if CheckMOTP.validate(attempted_record.otp_secret, attempted_record.otp_pin, otp_password, motp_maxperiod)
            # cache the otp so we can check against it next time
            old_otp.pop if old_otp.length == 5
            old_otp << otp_hash
            attempted_record.update_attribute(:otp_cache, old_otp.join(","))
          else
            generalize_credentials_error_messages? ?
              add_general_credentials_error :
              errors.add(:password, I18n.t('error_messages.password_invalid', :default => "is invalid"))
            return
          end
        end
      end
    end
  end
  
  class CheckMOTP
    def initialize
      @tmp_md5 = ''
    end
    
    def self.validate(secret,pin,otp,period=3)
      maxperiod = period * 60 # in seconds
      time = Time.now.utc.to_i
      ((time - maxperiod)..(time + maxperiod)).each do |n|
        md5 = generate_otp(n,secret,pin)
        next if md5 == @tmp_md5
        @tmp_md5 = md5
        
        return true if md5.downcase == otp.chomp.downcase
      end
      false
    end
    
    def self.generate_otp(time,secret,pin)
      Digest::MD5.hexdigest(time.to_s.chop << secret << pin.to_s)[0,6]
    end
  end
end
