
class tomcat (
  Stdlib::Absolutepath $deployment_base_dir = "/srv/",
  String $user                = 'tomcat',
  String $group               = 'tomcat',
  Integer $uid                 = 91,
  Integer $gid                 = 91,
  Boolean $manage_usergroup   = false,
  Boolean $manage_home        = true,
  Hash $instances             = {},
  Array[String] $packages     = [],
) {
  include stdlib

  if ($manage_usergroup == true) {
    if $deployment_base_dir =~ /^\/.+\/.+$'/ {
      fail("Path $deployment_base_dir should be at least at directory level 2")
    }

    group { $group:
      ensure => present,
      gid    => $gid,
    }
    user { "$user":
      ensure     => present,
      gid        => $group,
      shell      => '/bin/bash',
      home       => $deployment_base_dir,
      require    => Group["$group"],
      uid        => $uid,
      managehome => $manage_home,

    }
  }
  file { "/etc/init.d/tomcat":
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/tomcat/tomcat'
  }
  ensure_packages($packages)
  create_resources('tomcat::instance', $instances)
}
