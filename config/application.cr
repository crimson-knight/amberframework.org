require "amber"
require "markd"
require "../src/models/**"
require "../src/services/**"
require "../src/controllers/application_controller"
require "../src/controllers/**"

Amber::Server.configure do |settings|
  settings.name = "amberframework.org"
  settings.host = ENV["HOST"]? || "0.0.0.0"
  settings.port = ENV["PORT"]?.try(&.to_i) || 3000
  settings.secret_key_base = ENV["SECRET_KEY_BASE"]? || "amberframework-public-docs-no-session-data"
end
