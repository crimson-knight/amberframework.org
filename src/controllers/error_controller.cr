class Amber::Controller::Error < Amber::Controller::Base
  include ApplicationHelper

  def not_found
    render("404.ecr")
  end

  def internal_server_error
    render("500.ecr")
  end
end
