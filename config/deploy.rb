# config valid only for Capistrano 3.1
lock '3.1.0'

application = 'mars_dashing'
user = 'resure'
set :repo_url, 'git@github.com:resure/mars_dashing.git'

set :deploy_to, '/home/resure/apps/dashing'

namespace :deploy do

  task :setup do
    invoke 'deploy'
    invoke 'deploy:env:copy'
    invoke 'deploy:env:export'
    on roles(:app) do
      execute :sudo, "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
      execute :sudo, "service nginx restart"
    end
    invoke 'deploy:start'
  end

  namespace :env do
    task :copy do
      on roles(:app) do
        execute :cp, "#{current_path}/.env #{shared_path}/env"
      end
    end

    task :echo do
      on roles(:app) do
        execute :cat, "#{shared_path}/env"
      end
    end

    task :export do
      on roles(:app) do
        execute :rm, "#{current_path}/.env"
        execute :ln, "-s #{shared_path}/env #{current_path}/.env"
        execute :sudo, "foreman export -d #{current_path} --app #{application} --user #{user} upstart /etc/init"
      end
    end
  end

  task :push do
    invoke 'deploy'
    invoke 'deploy:env:export'
    invoke 'deploy:restart'
  end

  %w[start stop restart].each do |command|
    desc "#{command} application"
    task command do
      on roles(:app), in: :sequence, wait: 5 do
        execute :sudo, "#{command} #{application}"
      end
    end
  end

end
