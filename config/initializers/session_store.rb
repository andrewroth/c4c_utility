# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_c4c_utility_session',
  :secret      => '062e121266a61534f8a0ab8e963abea04a377b3dbf95a1987fbfa970c69dbb09f184b4c28734bbb9814ee00578f9d4c9b5fa2ac639c039e6c2ef45c5c975ed32'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
