require "authlogic_motp/version"
require 'authlogic_motp/acts_as_authentic'
require 'authlogic_motp/session'

ActiveRecord::Base.send(:include, AuthlogicMotp::ActsAsAuthentic)
Authlogic::Session::Base.send(:include, AuthlogicMotp::Session)
