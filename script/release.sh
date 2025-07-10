set -e

bundle exec rails db:migrate
bundle exec rails db:seed
bundle exec rails dojos:update_db_by_yaml
bundle exec rails news:import_from_yaml
bundle exec rails dojo_event_services:upsert
bundle exec rails podcasts:upsert
