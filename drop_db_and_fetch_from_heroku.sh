#!/bin/sh

set -eux

# NOTE: This script does NOT run if username != 'yasulab' in case.
#       Also, you need to have a permission to access Heroku database.
if [[ `whoami` != 'yasulab' ]]; then
    echo "# This executes breaking change in databases! Aborted."
    echo "# If you understand this correctly, change the flag and re-run this script."
    echo "(Aborted: '`whoami`' != 'yasulab')"
    echo ""
    exit 0
fi

# Drop development/test databases
RAILS_ENV=development DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:drop

# Copy production databse in Heroku to development database.
heroku pg:pull DATABASE_URL coderdojo_jp_development --app coderdojo-japan

# Create test databse to run test suites.
RAILS_ENV=test bundle exec rails db:migrate:reset
