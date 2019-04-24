####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Prerequisites](#prerequisites)
3. [Setup - The basics of getting started with tomcat](#setup)
    * [What tomcat affects](#what-tomcat-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with tomcat](#beginning-with-tomcat)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##Overview

The tomcat module installs the Apache Tomcat binary distribution.

## TODOs

- implement autodiscovery of minor releases
- improve download of archive

##Module Description

The Tomcat module installs the Apache Tomcat binary distribution onto your nodes.
You may set the Tomcat binary distribution package, the directory into which
it will install, the user that will own the package, and whether or not a number
of default Tomcat resources will be installed as well.

##Setup

###What tomcat affects

* Tomcat base directory

This module installs a standalone version of Apache Tomcat, separate
from any OS-supplied Tomcat package.

It should work on any Unix environment.

###Beginning with tomcat

`include 'tomcat'` in the puppet master's `site.pp` file is enough to get 
you up and running.  It can also be included in any other caller module.

Set this in `site.pp` or in your caller module and define:
```puppet
include tomcat
```
or, alternatively (to override the default parameters):
```puppet

class { 'tomcat':
  deployment_base_dir => '/srv/tomcat/',
  user                => 'tomcat1',
  group               => 'tomcat2',
  uid                 => 91,
  gid                 => 91,
  manage_usergroup    => true,
  instances           => {},
}
```
Then you can use the type `tomcat::instance`:

```puppet
tomcat::install { 'example.com-tomcat':
  source        => 'apache-tomcat-7.0.39.tar.gz',
  deploymentdir => '/home/example.com/apps/apache-tomcat',
  user          => 'example.com',
  group         => 'mygroup',
  default_webapp_docs        => 'present',
  default_webapp_examples    => 'present',
  default_webapp_hostmanager => 'present',
  default_webapp_manager     => 'present',
  default_webapp_root        => 'present'
}
```

##Usage

##Reference

###Classes

####Public Classes

* tomcat:  Main class
* tomcat::instance: Puppet resource that installs the Tomcat binary package.

####Private Classes

* tomcat::params:  The default configuration parameters.


#####`source`

The file that contains the Tomcat binary distribution.
This file must be in the files directory in the caller module.  
Only `.tar.gz` source archives are supported.

Default: **apache-tomcat-7.0.50.tar.gz**

#####`deploymentdir`

The absolute path to the directory where Tomcat will be installed.

Default: **/opt/tomcat7**

#####`user`

The Unix user that will own the Tomcat installation.

Default: **tomcat**

#####`group`

The Unix group that will own the Tomcat installation.

Default: **tomcat**

#####`default_webapp_docs`

Whether Tomcat's default webapp documentation should
be present or not. Valid arguments are "present" or "absent".

Default: **present**

#####`default_webapp_examples`

Whether Tomcat's default example webapps should
be present or not. Valid arguments are "present" or "absent".

Default: **present**

#####`default_webapp_hostmanager`

Whether Tomcat's default webapp for host management should be present or not.
Valid arguments are "present" or "absent".

Default: **present**

#####`default_webapp_manager`

Whether Tomcat's default webapp for server configuration should be present or not.
Valid arguments are "present" or "absent".

Default: **present**

#####`default_webapp_root`

Whether Tomcat's default webapp root directory should be present or not. 
Valid arguments are "present" or "absent".

Default: **present**

##Limitations

This module does not define the raw filesystem devices, nor mount
any filesystems.  Nor dies it create nor ensure the Unix user.
Make sure the filesystem in which the Tomcat install will reside
is created and mounted, and that the Unix user exists.

This module has been built and tested using Puppet 3.4.x. on RHEL6.  It should
work on all Unices, but your mileage may vary.

##Development

This module is far away fork of https://github.com/7terminals/puppet-tomcat and it is 
managed at 


Test with
```
bundle exec rake spec
```


