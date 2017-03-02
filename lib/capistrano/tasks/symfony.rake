namespace :symfony do
    # Gets the console file path.
    def get_console
        if File.file?('app/console.sh')
            'app/console.sh'
        elsif File.file?('app/console')
            'app/console'
        elsif File.file?('bin/console.sh')
            'bin/console.sh'
        elsif File.file?('bin/console')
            'bin/console'
        else
            raise 'Unreachable console file.'
        end
    end

    # Execute the given symfony command.
    def execute_cmd(cmd)
        path = get_console
        execute :php, path, cmd
    end

    desc 'ca:cl'
    task :cache do
        on roles(:web) do
            within release_path do
                execute_cmd 'ca:cl'
                execute_cmd 'ca:cl -e prod'
                execute_cmd 'ca:cl -e test'
            end
        end
    end

    desc 'Erase database and load fixtures.'
    task :init_db do
        on roles(:db) do
            within release_path do
                # TODO: Create db.
                execute_cmd 'do:sc:cr'
                execute_cmd 'do:sc:up --force'
                execute_cmd 'do:fi:lo -e prod' # Get env from stage.

                # ...
            end
        end
    end

    desc 'Update database schema'
    task :migrate do
        on roles(:db) do
            within release_path do
                parameter_file = "#{release_path}/app/config/parameters.yml"
                # TODO: Test if database already exists.
                if File.file?(parameter_file)
                    # parameters = Hash[File.read(parameter_file).split("\n").scan(/(.+?):\s*(.+)/)]
                    # parameters = File.read(parameter_file).gsub(/\s+/, ' ').split("\n").map { |i| i.split(/:\s*/) }

                    parameters = {}

                    File.open(parameter_file).each do |line|
                        split = line.split(/:\s*/)

                        parameters[split[0].strip] = split[1].strip unless split[0] == line || split[1].nil?
                    end
                else
                    raise "We didn't found the \"#{parameter_file}\" parameters file."
                end

                database_name = parameters['database_name']

                raise 'Impossible to create db without valid parameters' if database_name.nil?

                # execute :php, get_console, 'doctrine:query:sql', '"SHOW DATABASES;"'
                query_result = capture(:php, get_console, 'doctrine:query:sql', '"SHOW DATABASES;"')

                if query_result =~ /^(\w*\n)*$/
                    # We got a valid list.
                    # TODO Finish.
                else
                    raise 'Impossible to evaluate availables databases'
                end

                puts database_name
                puts query_result

                # TODO: Create them if not exists.
                # TODO

                # TODO: Find correct command.
                # raise NotImplementedError, 'Not yet'

                # TODO: Checks if we have migration bundle.

                # execute_cmd 'doctrine:migration:migrate'
            end
        end
    end

    desc 'Set the correct right on cache folders.'
    task :setfacl do
        on roles(:web) do
            within release_path do
                http_user = capture("ps aux | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d\\  -f1")

                sudo :setfacl, '-R', '-m', "u:'#{http_user}':rwX -m u:`whoami`:rwX app/cache app/logs"
                sudo :setfacl, "-dR -m u:'#{http_user}':rwX -m u:`whoami`:rwX app/cache app/logs"

                execute :chmod, '-R', '755', 'web'
            end
        end
    end
end
