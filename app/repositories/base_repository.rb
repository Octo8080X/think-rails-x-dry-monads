class BaseRepository
  include Dry::Monads[:result, :try]
end
