# moodle #

This is the moodle module. It provides the functionality to install Moodle in a single host or multiple host (MySQL DB could be on a second host).

The approach is to let each module to manage it's own stuff so it depends on some puppetlabs modules.

The usage is:

# These are the requirements you have to place in the node you want to install
		package { mysql: ensure => present; }
		Package { ensure => "installed" }
		package { "httpd": }
		package { "php":   }
		package { "php-mysql":   }
		package { "php-mbstring": }
		package { "php-xml":   }
		package { "php-xmlrpc": }
		package { "php-soap": }
		package { "php-gd": }
		package { "php-intl": }
		package { zip: ensure => present; }

	# comes the proper Moodel class
			class { 'moodle':
			  tarball_url => 'http://sourceforge.net/projects/moodle/files/Moodle/stable23/moodle-2.3.3.tgz',
			  $db_host => 'localhost',
			  $db_name => 'moodle'
			  $db_user => 'moodle'
			  $db_password => 'moodle'
			}

The code is still under development, and in a pre-alfa stage, but should manage to install a working moodle installation.

TODO:
- Overall check
- using also package and not only the tgz
