define tomcat::instance (
  String $instancename                                                   = $title,
  String $downloadurl,
  String $tarball,
  Stdlib::Absolutepath $deploymentdir                                    = $::tomcat::deployment_base_dir,
  String $user                                                           = $tomcat::user,
  String $group                                                          = $tomcat::group,
  Boolean $manage_usergroup                                              = false,
  Boolean $manage_setenv                                                 = true,
  Variant[Enum['present', 'absent'], String] $default_webapp_docs        = absent,
  Variant[Enum['present', 'absent'], String] $default_webapp_examples    = absent,
  Variant[Enum['present', 'absent'], String] $default_webapp_hostmanager = present,
  Variant[Enum['present', 'absent'], String] $default_webapp_manager     = present,
  Variant[Enum['present', 'absent'], String] $default_webapp_root        = present,
  Boolean $enable_service                                                = true,
  Boolean $notify_service                                                = true,
  Variant[Enum['running', 'stopped'], String] $ensure                    = 'running',
  Stdlib::Absolutepath $logbasedir                                       = "/var/log/tomcat",
  String $javaheapopts                                                   = "-Xms256M -Xmx768M",
  String $javaopts                                                       = "",
  String $adminuser,
  String $adminpassword,
  String $mysqldbjar                                                     = "",
  String $mariadbjar                                                     = "",
  String $context_xml_template                                           = 'tomcat/context.xml.erb',
  String $setenv_template                                                = 'tomcat/setenv.sh.erb',
  String $server_xml_template                                            = 'tomcat/server.xml.erb',
  Optional[String] $root_xml_template                                    = undef,
  Hash $template_params                                                  = {},
  String $instance_archive_base_logdir                                   = "",
  String $port_prefix                                                    = '',
  String $port_sub_prefix                                                = '8',
  String $debug_port                                                     = "no",
  String $maxThreads                                                     = "100",
  String $max_header_size                                                = "4096",
  String $max_PostSize                                                   = "10000000",
  String $max_ParameterCount                                             = "40000",
  Array[String] $setenv_extra                                            = [],
  String $logrotate_crontab_spec                                         = "0 3 * * *",
) {

  ## VALIDATES
  if $downloadurl !~ /^http.*\/apache-tomcat-.*\.tar\.gz$/ {
    fail("You have to download a tar.gz file : $downloadurl")
  }

  ## Setup instance

  $cachedir = "/usr/local/src/working-tomcat-${instancename}"

  # resource defaults for Exec
  Exec {
    path => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'],
  }

  # working directory to untar tomcat
  file { $cachedir:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => '0644',
  }

  exec { "${cachedir}/${tarball}":
    command => "curl -q -o '${cachedir}/${tarball}' '$downloadurl'",
    cwd     => "${cachedir}/",
    creates => "${cachedir}/${tarball}",
    user    => $user,
    require => File[$cachedir],
    unless  => "gunzip -t '${cachedir}/${tarball}'"
  }
  file { "${cachedir}/${tarball}":
    ensure  => present,
    mode    => '0644',
    require => Exec["${cachedir}/${tarball}"],
  }
  exec { "extract_tomcat-${instancename}":
    cwd     => $cachedir,
    command => "mkdir extracted; tar -C extracted -xzf ${tarball} && touch .tomcat_extracted",
    creates => "${cachedir}/.tomcat_extracted",
    user    => $user,
    require => File["${cachedir}/${tarball}"],
  }

  exec { "create_target_tomcat-${instancename}":
    cwd     => '/',
    command => "mkdir -p ${deploymentdir}/",
    creates => $deploymentdir,
    require => Exec["extract_tomcat-${instancename}"],
  }

  if ($manage_usergroup == true) {
    if !defined(Group["$group"]) {
      group { "$group":
        ensure => present,
      }
    }
    if !defined(User["$user"]) {
      user { "$user":
        gid     => $group,
        shell   => '/bin/bash',
        home    => $deploymentdir,
        notify  => Exec["move_tomcat-${instancename}"],
        require => Group["$group"]
      }
    }
  }

  exec { "move_tomcat-${instancename}":
    cwd     => $cachedir,
    command => "cp -a extracted/apache-tomcat*/* ${deploymentdir} && chown -R ${user}:${group} ${deploymentdir}",
    creates => "${deploymentdir}/lib/catalina.jar",
    require => Exec["create_target_tomcat-${instancename}"],
    notify  => File["/etc/init.d/tomcat-${instancename}"],
  }

  if ($default_webapp_docs == 'absent') {
    file { "${deploymentdir}/webapps/docs":
      ensure  => absent,
      recurse => true,
      force   => true,
      require => Exec["move_tomcat-${instancename}"],
    }
  }

  if ($default_webapp_examples == 'absent') {
    file { "${deploymentdir}/webapps/examples":
      ensure  => absent,
      recurse => true,
      force   => true,
      require => Exec["move_tomcat-${instancename}"],
    }
  }

  if ($default_webapp_hostmanager == 'absent') {
    file { "${deploymentdir}/webapps/host-manager":
      ensure  => absent,
      recurse => true,
      force   => true,
      require => Exec["move_tomcat-${instancename}"],
    }
  }

  if ($default_webapp_manager == 'absent') {
    file { "${deploymentdir}/webapps/manager":
      ensure  => absent,
      recurse => true,
      force   => true,
      require => Exec["move_tomcat-${instancename}"],
    }
  }

  if ($default_webapp_root == 'absent') {
    file { "${deploymentdir}/webapps/ROOT":
      ensure  => absent,
      recurse => true,
      force   => true,
      require => Exec["move_tomcat-${instancename}"],
    }
  }

  file { "/etc/init.d/tomcat-${instancename}":
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('tomcat/tomcat-server.erb'),
  }

  if !defined(File["$logbasedir/"]) {
    file { "$logbasedir/":
      ensure => "directory",
      owner  => "root",
      group  => "root",
      mode   => '0755',
    }
  }

  file { "$logbasedir/$instancename":
    ensure  => "directory",
    owner   => $user,
    group   => $group,
    mode    => '0750',
    require => File["$logbasedir/"]
  }

  file { "${deploymentdir}/logs":
    ensure  => 'link',
    target  => "$logbasedir/$instancename",
    force   => true,
    purge   => true,
    require => Exec["move_tomcat-${instancename}"],
  }

  if ($mysqldbjar =~ /^http.*/) {
    exec { "download_mysql_driver":
      command => "curl -q -o ${deploymentdir}/lib/mysql-connector-java.jar $mysqldbjar",
      cwd     => "${deploymentdir}/lib/",
      creates => "${deploymentdir}/lib/mysql-connector-java.jar",
      user    => $user,
      require => [Exec["move_tomcat-${instancename}"], Exec["extract_tomcat-${instancename}"]],
    }
    if $notify_service {
      Exec['download_mysql_driver'] ~> Service["tomcat-${instancename}"]
    }

  }elsif ($mysqldbjar =~ /^\//) {
    file { "${deploymentdir}/lib/mysql-connector-java.jar":
      ensure  => 'link',
      target  => $mysqldbjar,
      force   => true,
      purge   => true,
      require => [Exec["move_tomcat-${instancename}"], Exec["extract_tomcat-${instancename}"]],
      notify  => Service["tomcat-${instancename}"],
    }
    if $notify_service {
      File["${deploymentdir}/lib/mysql-connector-java.jar"] ~> Service["tomcat-${instancename}"]
    }
  }

  if ($mariadbjar =~ /^http.*/) {
    exec { "download_mariadb_driver_${instancename}":
      command => "curl -q -o ${deploymentdir}/lib/mariadb-connector-java.jar $mariadbjar",
      cwd     => "${deploymentdir}/lib/",
      creates => "${deploymentdir}/lib/mariadb-connector-java.jar",
      user    => $user,
      notify  => Service["tomcat-${instancename}"],
      require => [Exec["move_tomcat-${instancename}"], Exec["extract_tomcat-${instancename}"]],
    }
    if $notify_service {
      Exec["download_mariadb_driver_${instancename}"] ~> Service["tomcat-${instancename}"]
    }
  }elsif($mariadbjar =~ /^\//) {
    file { "${deploymentdir}/lib/mariadb-connector-java.jar":
      ensure  => 'link',
      target  => $mariadbjar,
      force   => true,
      purge   => true,
      require => Exec["move_tomcat-${instancename}"],
      require => [Exec["move_tomcat-${instancename}"], Exec["extract_tomcat-${instancename}"]],
    }
    if $notify_service {
      File["${deploymentdir}/lib/mariadb-connector-java.jar"] ~> Service["tomcat-${instancename}"]
    }
  }

  file { "${deploymentdir}/conf/tomcat-users.xml":
    owner   => $user,
    group   => $group,
    mode    => '0700',
    content => template('tomcat/tomcat-users.conf.erb'),
    require => Exec["move_tomcat-${instancename}"],
  }

  file { "${deploymentdir}/conf/jmxremote.password":
    owner   => $user,
    group   => $group,
    mode    => '0700',
    content => "${adminuser} ${adminpassword}",
    require => Exec["move_tomcat-${instancename}"],
  }

  file { "${deploymentdir}/conf/jmxremote.access":
    owner   => $user,
    group   => $group,
    mode    => '0700',
    content => "${adminuser} readwrite",
    require => Exec["move_tomcat-${instancename}"],
  }

  if $notify_service {
    File["${deploymentdir}/conf/tomcat-users.xml"] ~> Service["tomcat-${instancename}"]
  }

  file { "${deploymentdir}/conf/context.xml":
    owner   => $user,
    group   => $group,
    mode    => '0740',
    content => template($context_xml_template),
    require => Exec["move_tomcat-${instancename}"],
  }
  file { "${deploymentdir}/conf/server.xml":
    owner   => $user,
    group   => $group,
    mode    => '0740',
    content => template($server_xml_template),
    require => Exec["move_tomcat-${instancename}"],
  }

  if $root_xml_template {
    file { ["${deploymentdir}/conf/Catalina/", "${deploymentdir}/conf/Catalina/localhost"]:
      ensure => 'directory',
      owner  => $user,
      group  => $group,
      mode   => '0755',
    }
    ->file { "${deploymentdir}/conf/Catalina/localhost/ROOT.xml":
      owner   => $user,
      group   => $group,
      mode    => '0640',
      content => template($root_xml_template),
      require => Exec["move_tomcat-${instancename}"],
    }
  }

  if $manage_setenv {
    file { "${deploymentdir}/bin/setenv.sh":
      owner   => $user,
      group   => $group,
      mode    => '0700',
      content => template($setenv_template),
      require => Exec["move_tomcat-${instancename}"],
    }
  }

  service { "tomcat-${instancename}":
    enable     => $enable_service,
    ensure     => $ensure,
    hasstatus  => true,
    hasrestart => true,
    require    => [
      File["$logbasedir/$instancename"],
      File["${deploymentdir}/conf/tomcat-users.xml"],
      File["${deploymentdir}/conf/jmxremote.access"],
      File["${deploymentdir}/conf/jmxremote.password"],
      File["${deploymentdir}/conf/server.xml"],
      File["${deploymentdir}/conf/context.xml"],
      File["${deploymentdir}/bin/setenv.sh"],
      File["/etc/init.d/tomcat-${instancename}"],
    ],
  }

  if ($instance_archive_base_logdir != "") {
    file { "/etc/cron.d/tomcat-${instancename}":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "
PATH=/usr/lib/sysstat:/usr/sbin:/usr/sbin:/usr/bin:/sbin:/bin
${logrotate_crontab_spec} root ${deploymentdir}/bin/logrotate.sh 2>&1|logger -t tomcat-${instancename}
      ",
      require => File["${deploymentdir}/bin/logrotate.sh"],
    }

    file { "${deploymentdir}/bin/logrotate.sh":
      owner   => $user,
      group   => $group,
      mode    => '0750',
      content => template('tomcat/logrotate.sh.erb'),
      require => Service["tomcat-${instancename}"],
    }
  }
}
