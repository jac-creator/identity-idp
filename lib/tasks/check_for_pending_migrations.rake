namespace :db do
  desc 'Raise an error if migrations are pending'
  task check_for_pending_migrations: :environment do
    instance_role_filename = '/etc/login.gov/info/role'
    instance_role = File.exist?(instance_role_filename) &&
                    File.read(instance_role_filename).strip

    if instance_role == 'migration'
      warn('Skipping pending migration check on migration instance')
    else
      ActiveRecord::Migration.check_pending!(ActiveRecord::Base.connection)
    end
  end
end