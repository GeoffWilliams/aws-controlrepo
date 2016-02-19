class role::puppet::master {
  include profile::base
  include r_profile::puppet::r10k

  class { "r_profile::puppet::master":
    hierarchy => [ "aws" ],
  }
}
