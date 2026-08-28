ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Parallelization disabled: each worker gets its own db (bus_reservation_test_N),
    # so multi-worker runs were spawning one database per CPU core. workers: 1 keeps
    # everything on the single bus_reservation_test database.
    parallelize(workers: 1)

    # Test data via FactoryBot + Faker instead of fixtures.
    # See kos/decisions/rails-testing-minitest-factorybot-faker.md
    include FactoryBot::Syntax::Methods

    # Add more helper methods to be used by all tests here...
  end
end
