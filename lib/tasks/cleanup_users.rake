namespace :users do
  desc "Limpar usuários não confirmados há mais de 24 horas"
  task cleanup_unconfirmed: :environment do
    deleted_count = User.where("confirmed_at IS NULL AND created_at < ?", 24.hours.ago).delete_all
    puts "#{deleted_count} usuários não confirmados foram deletados."
  end
end
