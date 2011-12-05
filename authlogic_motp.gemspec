# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "authlogic_motp/version"

Gem::Specification.new do |s|
  s.name        = "authlogic_motp"
  s.version     = AuthlogicMotp::VERSION
  s.authors     = ["Martin Chandler"]
  s.email       = ["browntigerz.lair@gmail.com"]
  s.homepage    = "http://github.com/browntiger/authlogic_motp"
  s.summary     = %q{Extension of the Authlogic library to add Mobile-OTP support.}
  s.description = %q{Extension of the Authlogic library to add Mobile-OTP support.}
  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = ["README.rdoc"]

#  s.rubyforge_project = "authlogic_motp"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
#  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  s.add_runtime_dependency "authlogic"
end
