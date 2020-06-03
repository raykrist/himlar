# manage cloudkitty rating service
class profile::openstack::rating (
  $manage_firewall   = false,
  $manage_wsgi       = false,
  $manage_processor  = false,
  $rating_ports      = ['8889'],
  $firewall_source   = "${::network_trp1}/${::netmask_trp1}"
)
{

  include ::cloudkitty
  include ::cloudkitty::config
  include ::cloudkitty::logging
  include ::cloudkitty::keystone::authtoken
  include ::cloudkitty::api

  if $manage_wsgi {
    include ::cloudkitty::wsgi::apache
  }

  if $manage_processor {
    include ::cloudkitty::processor
  }

  if $manage_firewall {
    profile::firewall::rule { '240 cloudkitty accept tcp':
      dport  => $rating_ports,
      proto  => 'tcp',
      source => $firewall_source
    }
  }

}
