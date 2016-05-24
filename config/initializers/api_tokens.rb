# This class allows us to set different api tokens in prod and test env
# Also just organizes the keys in general
class ApiTokens
  class << self
    attr_accessor :zillow_key, :google_key, :census_key, :mls_key
  end
end