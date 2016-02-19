# site.pp

# classify nodes based on role fact if present
node default {
  include role::fact_classified
}


# puppet master
node "pe-puppet.localdomain" {
  include role::puppet::master
}
