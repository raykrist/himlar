#
class profile::network::services(
  $manage_dhcp        = false,
  $manage_nat         = false,
  $manage_mgmt_nat    = false,
  $manage_dns_records = false,
  $manage_dhcp_rsvs   = false,
  $dns_proxy          = false,
  $http_proxy         = false,
  $ntp_server         = false,
  $manage_firewall    = true,
  $firewall_extras    = {}
) {
  $networks = hiera_hash('networks', false)

  if $networks {
    $subnet = $networks[$location]['subnet']
    $dhcp   = $networks[$location]['dhcp']
    $nat    = $networks[$location]['nat']

    if $manage_dhcp {
      include ::dnsmasq
      dnsmasq::conf { 'disable-dns': prio => '01', content => "port=0\n" }

      # Define dhcp ranges per subnet
      $dhcp_keys = keys($dhcp)
      $dhcp_resources = prefix($dhcp_keys, 'dhcp_')
      profile::network::service::dhcp { $dhcp_resources:
        subnet => $subnet,
        dhcp   => $dhcp,
      }
    }

    if $manage_nat {
      # This node is a gw, enable IP fwd
      sysctl::value { 'net.ipv4.ip_forward':
        value => 1,
      }
    }

    if $manage_mgmt_nat {
      # Will set up iptables nat for mgmt based on iniface and outiface from
      # network hash i common/common.yaml
      profile::firewall::rule { '050 snat for mgmt':
        chain  => 'POSTROUTING',
        proto  => 'all',
        extras => {
          action   => undef,
          jump     => 'MASQUERADE',
          outiface => $nat['mgmt']['outiface'],
          table    => 'nat',
        }
      }
      profile::firewall::rule { '050 forward for mgmt':
        chain   => 'FORWARD',
        iniface => $nat['mgmt']['iniface'],
        proto   => 'all',
        extras  => {
          outiface => $nat['mgmt']['outiface']
        }
      }
    }

    if $ntp_server {
      # This node is a ntp-server. Default config is fine, open fw
      if $manage_firewall {
        profile::firewall::rule { '022 ntp-server accept udp':
          port   => 123,
          proto  => 'udp',
          extras => $firewall_extras
        }
      }
    }

    if $manage_dns_records {
      $dns_options = hiera_hash('profile::network::services::dns_options')
      $dns_records = hiera_hash('profile::network::services::dns_records')
      $record_types = keys($dns_records)

      profile::network::service::dns_record_type { $record_types:
        options => $dns_options,
        records => $dns_records,
      }

    }

    if $manage_dhcp_rsvs {
      create_resources(dhcp::host, hiera_hash('profile::network::services::dhcp_reservation', {}))
    }

    # Enable a dns proxy server
    if $dns_proxy {
      include ::dnsmasq

      if $manage_firewall {
        profile::firewall::rule { '020 dns-proxy accept tcp':
          port   => 53,
          proto  => 'tcp',
          extras => $firewall_extras
        }
        profile::firewall::rule { '021 dns-proxy accept udp':
          port   => 53,
          proto  => 'udp',
          extras => $firewall_extras
        }
      }
    }

    # Enable a http proxy server
    if $http_proxy {
      include ::tinyproxy

      if $manage_firewall {
        profile::firewall::rule { '110 http-proxy accept tcp':
          port   => 8888,
          proto  => 'tcp',
          state  => ['NEW','ESTABLISHED'],
          extras => $firewall_extras
        }
      }
    }

  } else {
    warning("hiera returns no data for 'networks', so we're noop!")
  }
}
