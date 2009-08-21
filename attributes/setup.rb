db_password = ""
chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
20.times { |i| db_password << chars[rand(chars.size-1)] }

railsapps Mash.new unless attribute?("railsapps")
railsapps[:spree]                        = Mash.new        unless railsapps.has_key?(:spree)
railsapps[:spree][:db]                   = Mash.new        unless railsapps[:spree].has_key?(:db)
railsapps[:spree][:db][:user]            = "spree_db" unless railsapps[:spree][:db].has_key?(:user)
railsapps[:spree][:db][:password]        = db_password unless railsapps[:spree][:db].has_key?(:password)
railsapps[:spree][:db][:database]        = "spree" unless railsapps[:spree][:db].has_key?(:database_stem)
railsapps[:spree][:app]                  = Mash.new        unless railsapps[:spree].has_key?(:app)
railsapps[:spree][:app][:user]           = "www-data" unless railsapps[:spree][:app].has_key?(:user)
railsapps[:spree][:app][:group]          = "www-data" unless railsapps[:spree][:app].has_key?(:group)
railsapps[:spree][:app][:path]           = "/srv/spree" unless railsapps[:spree][:app].has_key?(:path)
railsapps[:spree][:app][:log_dir]        = "/var/log/spree" unless railsapps[:spree][:app].has_key?(:log_dir)
railsapps[:spree][:app][:pool_size]      = "4" unless railsapps[:spree][:app].has_key?(:pool_size)
railsapps[:spree][:host]                 = `hostname -f`.downcase.strip unless railsapps[:spree].has_key?(:host)