# Dry-rb configuration
require 'dry-types'
require 'dry-validation'
require 'dry-monads'

# Auto-load application types and contracts
Rails.application.config.autoload_paths += %W[
  #{Rails.root}/app/lib
  #{Rails.root}/app/services
  #{Rails.root}/app/lib/contracts
]
