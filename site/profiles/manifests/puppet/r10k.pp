class profile::puppet::r10k (
  $remote = hiera("profiles::puppet::r10k::remote"),
  $environmentpath = $::profiles::puppet::params::environmentpath,
) inherits ::profile::puppet::params {
  file { 'r10k_config':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    path    => '/etc/puppetlabs/r10k/r10k.yaml',
    content => template('profile/r10k.yaml.erb'),
  }
}
