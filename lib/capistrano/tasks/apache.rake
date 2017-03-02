namespace :apache do
    desc 'Generates then installs a valid VHOST'
    task :conf do
        on roles(:web) do
            erb = File.read 'lib/capistrano/templates/apache_conf.erb'

            set :server_name, ask('Domain name : ', 'lapin.fr')
            set :config_name, ask('Config file name : ', fetch(:server_name))
            set :site_root, '/home/jonathan/temp/cdpn/cap/remote/current/web'

            config_path = "/tmp/apache2_#{fetch(:config_name)}.conf"
            conf_file = ERB.new(erb).result(binding)
            upload! StringIO.new(conf_file), config_path

            puts config_path, "/etc/apache2/sites-available/#{fetch(:config_name)}.conf"
            sudo :mv, '--force', config_path, "/etc/apache2/sites-available/#{fetch(:config_name)}.conf"

            sudo :a2ensite, fetch(:config_name)
            sudo :service, :apache2, :restart
        end
    end
end
