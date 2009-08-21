name    "spree"
description 'Run a spree instance on this node'
depends "apache2"
depends "passenger_apache2"
depends "passenger_apache2::mod_rails"
depends "mysql::client"
depends "database"
depends "apt"
depends "gems"
depends "git"
maintainer 'Jim Van Fleet'
maintainer_email 'jvanfleet@tradeking.com'