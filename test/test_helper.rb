ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Test data via FactoryBot + Faker instead of fixtures.
    # See kos/decisions/rails-testing-minitest-factorybot-faker.md
    include FactoryBot::Syntax::Methods

    # Add more helper methods to be used by all tests here...
  end
end
