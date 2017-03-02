namespace :php do
    desc 'Install composer dependencies.'
    task :composer do
        on roles(:web) do
            within release_path do
                execute :composer, :install
            end
        end
    end
end
