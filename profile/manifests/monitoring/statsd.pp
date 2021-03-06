#
class profile::monitoring::statsd(
  $manage                    = false,
  $manage_firewall           = false,
  $firewall_extras           = {}
) {

  if $manage {
    include ::statsd
  }

  if $manage_firewall {
    profile::firewall::rule { '413 statsd accept udp':
      dport       => 8125,
      proto       => 'udp',
      destination => $::ipaddress_mgmt1,
      extras      => $firewall_extras,
    }
  }
}
