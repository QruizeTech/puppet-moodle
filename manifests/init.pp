# Class: moodle
#
# This module manages moodle
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
class moodle (
  $doc_root         = $moodle::params::doc_root,
  $use_package      = $moodle::params::use_package,
  $tarball_url      = $moodle::params::tarball_url,
  $db_host          = $moodle::params::db_host,
  $db_name          = $moodle::params::db_name,
  $db_user          = $moodle::params::db_user,
  $db_password      = $moodle::params::db_password,
  $admin_user       = $moodle::params::admin_user,
  $admin_password   = $moodle::params::admin_password,
  $site_url         = $moodle::params::site_url,
  $site_name        = $moodle::params::site_name,
  $site_desc        = $moodle::params::site_desc,
  $moodle_data_path = $moodle::params::moodle_data_path,
  $package_ensure   = 'latest',
  $max_memory       = '2048') inherits moodle::params {
  #require mysql
  #require apache

  $web_dir = $moodle::params::web_dir

  # Parse the url
  $tarball_dir = regsubst($tarball_url, '^.*?/(\d\.\d+).*$', '\1')
  $tarball_name = regsubst($tarball_url, '^.*?/(moodle-\d\.\d+.*tgz)$', '\1')
  # $moodle_dir = regsubst($tarball_url, '^.*?/(moodle-\d\.\d+\.\d+).*$', '\1')
  $moodle_dir = 'moodle'
  $moodle_install_path = "${web_dir}/${moodle_dir}"

  notify { "The tarball_dir is: ${tarball_dir}":
  }

  notify { "The tarball_name is: ${tarball_name}":
  }

  notify { "The moodle_dir is: ${moodle_dir}":
  }

  notify { "The moodle_install_path is: ${moodle_install_path}":
  }

  # Specify dependencies
  # It needs MySQL client
  #  Class['mysql'] -> Class['moodle']
  #  Class['apache'] -> Class['moodle']
  #Class['apache::mod::php'] -> Class['moodle']
  Package['zip'] -> Class['moodle']
  Package['mysql'] -> Class['moodle']
  Package['httpd'] -> Class['moodle']
  Package['php'] -> Class['moodle']
  Package['php-mbstring'] -> Class['moodle']
  Package['php-mysql'] -> Class['moodle']
  Package['php-xml'] -> Class['moodle']
  Package['php-xmlrpc'] -> Class['moodle']
  Package['php-soap'] -> Class['moodle']
  Package['php-gd'] -> Class['moodle']
  Package['php-intl'] -> Class['moodle']

  #  class { 'apache': }
  #  class { 'apache::mod::php': }
  #
  # we'll need a DB and a user
  #@@mysql::db { $db_name:
  #  user     => $db_user,
  #  password => $db_password,
  #  host     => $db_host,
  #  grant    => ['all'],
  #  tag      => 'moodle_db',
  #    unless   => '/usr/bin/mysql -h ${db_host} -u ${db_user} -p${db_password} -NBe "show databases"',
  #}

  notify { "The DB data are: ${db_name} ${db_user} ${db_password} ${db_host}":
  }

  # Moodle preparation
  #
  # If we install moodle from package
  if $use_package == true {
    notify { "The $use_package is: ${use_package}":
    }

  } else {
    notify { "The $use_package is: ${use_package}":
    }

    # if we install moodle from tar
    #
    # set moodle_data folder owned by apache
    file { $moodle_data_path:
      ensure => directory,
      owner  => $moodle::params::web_user,
      group  => $moodle::params::web_group,
    }

    # Download and install MediaWiki from a tarball
    exec { "get-moodle":
      cwd     => $web_dir,
      command => "/usr/bin/wget ${tarball_url}",
      creates => "${web_dir}/${tarball_name}",
    #      subscribe => File['moodle_conf_dir'],
    }

    exec { "unpack-moodle":
      cwd       => $web_dir,
      command   => "/bin/tar -xvzf ${tarball_name} && /bin/chown -R $moodle::params::web_user:$moodle::params::web_group /var/www/html/moodle && /bin/chmod 755 -R /var/www/html/moodle && /bin/mkdir $moodle_data_path && /bin/chown -R $moodle::params::web_user:$moodle::params::web_group $moodle_data_path",
      creates   => $moodle_install_path,
      subscribe => Exec['get-moodle'],
    }
  
# We have the moodle stuff in the file system now we need to configure it
  # First we chack if the DB exist
  #
  # Creates MoodleData folder
  exec { "check-moodle-database":
    #      cwd       => $web_dir,
    command   => "/usr/bin/mysql -h ${db_host} -u ${db_user} -p${db_password} -NBe 'show databases'",
    #      creates   => $moodle_install_path,
    subscribe => Exec['unpack-moodle'],
  }

  augeas { "sudoapache":
    context => "/files/etc/sudoers",
    changes => [
      "set spec[user = '$moodle::params::web_user']/user \"$moodle::params::web_user\"",
      "set spec[user = '$moodle::params::web_user']/host_group/host \"ALL\"",
      "set spec[user = '$moodle::params::web_user']/host_group/command \"ALL\"",
      "set spec[user = '$moodle::params::web_user']/host_group/command/runas_user \"ALL\"",
      "set spec[user = '$moodle::params::web_user']/host_group/command/tag \"NOPASSWD\"",
      "set Defaults[type=':$moodle::params::web_user']/type :$moodle::params::web_user",
      "set Defaults[type=':$moodle::params::web_user']/requiretty/negate \"\""],
  }


  exec { "${name}-install_script":
    cwd       => "${moodle_install_path}/admin/cli",
    # su --shell=/bin/bash --session-command="/usr/bin/php /var/www/html/moodle/admin/cli/install.php --help" apache
    command => "/usr/bin/sudo -u apache /usr/bin/php install.php     \
                        --lang=en                                \
                        --dataroot=${moodle_data_path}           \
                        --dbhost=${db_host}                      \
                        --dbtype=mysqli                         \
                        --dbname=${db_name}                      \
                        --dbuser=${db_user}                      \
                        --dbpass=\'${db_password}\'              \
                        --wwwroot=http://${site_url}             \
                        --adminuser=${admin_user}                \
                        --adminpass=\'${admin_password}\'        \
                        --non-interactive                        \
                        --fullname=\'${site_name}\'              \
                        --shortname=\'${site_desc}\'             \
                        --agree-license ",
    creates   => "${moodle_install_path}/config.php",
    subscribe => Exec['check-moodle-database'],
    user      => $moodle::params::web_user,
    group     => $moodle::params::web_group,
    require   => Augeas['sudoapache']
  }

  #       sudo -u apache /usr/bin/php install.php --lang=it --dataroot=/var/moodledata --dbuser=moodle --dbpass=moodle
  #       --wwwroot=http://moodle.scuole-dev.cloudlabcsi.eu --adminuser=admin --adminpass='1!moodlE' --non-interactive
  #       --fullname='Sito di prova' --shortname='short' --agree-license

  #apache::vhost { $site_url:
  #  priority => '20',
  #  port     => '80',
  #  docroot  => $moodle_install_path,
    #docroot_owner => $moodle::params::web_user,
    #docroot_group => $moodle::params::web_group,
  #}

}
}
