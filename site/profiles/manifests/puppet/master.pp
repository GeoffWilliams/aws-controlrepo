class profiles::puppet::master (
    $hiera_eyaml = true,
    $autosign = false,
    $proxy = hiera("profiles::puppet::master::proxy", false),
    $sysconf_puppet = $::profiles::puppet::params::sysconf_puppet,
    $sysconf_puppetserver = $::profiles::puppet::params::sysconf_puppetserver,
    $puppet_agent_service = $::profiles::puppet::params::puppet_agent_service,
#    $deploy_pub_key = "",
#    $deploy_private_key = "",
#    $environmentpath = $::profiles::puppet::params::environmentpath,
) inherits profiles::puppet::params {
  validate_bool($hiera_eyaml,$autosign)

  File {
    owner => "root",
    group => "root",
  }

  class { "hiera":
    hierarchy => [
      "nodes/%{clientcert}",
      "app_tier/%{app_tier}",
      "env/%{environment}",
      "common",
    ],
    datadir   => $profiles::puppet::params::hieradir,
    backends  => $backends,
    eyaml     => $hiera_eyaml,
    owner     => "pe-puppet",
    group     => "pe-puppet",
    provider  => "pe_puppetserver_gem",
    notify    => Service["pe-puppetserver"],
  }

  if $autosign {
    file { "autosign":
      ensure  => "present",
      content => "*",
      path    => "${::settings::confdir}/autosign.conf",
    }
  }

  # puppet service force startup on 2015.2.0
  if $pe_server_version == "2015.2.0" {
    service { "puppet":
      ensure => running,
      enable => true,
    }
  }


  #
  # Proxy server monkey patching
  #
  if $proxy {
    $regexp = 'https?://(.*?@)?([^:]+):(\d+)'
    $proxy_host = regsubst($proxy, $regexp, '\2')
    $proxy_port = regsubst($proxy, $regexp, '\3')
  }
  $proxy_ensure = $proxy ? {
    /.*/    => present,
    default => absent,
  }

  $http_proxy_var = "http_proxy=${proxy}"
  $https_proxy_var = "https_proxy=${proxy}"

  Ini_setting {
    ensure => $proxy_ensure,
  }

  # PMT (puppet.conf)
  ini_setting { "pmt proxy host":
    path     => $puppetconf,
    section  => "user",
    setting  => "http_proxy_host",
    value    => $proxy_host,
  }

  ini_setting { "pmt proxy port":
    path    => $puppetconf,
    section => "user",
    setting => "http_proxy_port",
    value   => $proxy_port,
  }

  # Enable pe-puppetserver to work with proxy
  file_line { "pe-puppetserver http_proxy":
    ensure => $proxy_ensure,
    path   => $sysconf_puppetserver,
    line   => $http_proxy_var,
    match  => "^http_proxy=",    
    notify => [ Service["pe-puppetserver"],
                Exec["systemctl_daemon_reload"] ],
  }

  file_line { "pe-puppetserver https_proxy":
    ensure => $proxy_ensure,
    path   => $sysconf_puppetserver,
    line   => $https_proxy_var,
    match  => "^https_proxy=",
    notify => [ Service["pe-puppetserver"],
                Exec["systemctl_daemon_reload"] ],
  }

  file_line { "puppet agent http_proxy":
    ensure => $proxy_ensure,
    path   => $sysconf_puppet,
    line   => $http_proxy_var,
    match  => "^http_proxy=",
    notify => [ Service[$puppet_agent_service],
                Exec["systemctl_daemon_reload"] ],
  }

  file_line { "puppet agent https_proxy":
    ensure => $proxy_ensure,
    path   => $sysconf_puppet,
    line   => $https_proxy_var,
    match  => "^https_proxy=",
    notify => [ Service[$puppet_agent_service],
                Exec["systemctl_daemon_reload"] ],
  }

}
