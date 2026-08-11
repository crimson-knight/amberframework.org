class BlogController < ApplicationController
  @posts = YAML.parse_all File.read("blog/posts.yml")

  def index
    render("index.ecr")
  end

  def show
    date = %{#{params["year"]}/#{params["month"]}/#{params["day"]}}
    id = params["id"]
    filepath = "blog/#{date}/#{id}.md"
    post = @posts.find do |item|
      item["file"].to_s == filepath
    end
    if post
      render("show.ecr")
    else
      raise Amber::Exceptions::RouteNotFound.new(request)
    end
  end
end
