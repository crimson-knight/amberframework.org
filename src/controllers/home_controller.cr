class HomeController < ApplicationController
  def index
    render("index.ecr")
  end

  def media
    render("media.ecr")
  end

  def guides
    redirect_to location: "/docs", status: 302
  end

  def legacy_guides_redirect
    path = params["path"]?
    if path && !path.to_s.empty?
      redirect_to location: "/docs/v1.4.1/guides/#{path}", status: 301
    else
      redirect_to location: "/docs/v1.4.1/guides", status: 301
    end
  end

  def getting_started
    redirect_to location: "/docs/v2/getting-started", status: 301
  end

  def examples
    redirect_to location: "/docs/v2/examples", status: 301
  end

  def amber
    path = params["path"]?
    if path && !path.to_s.empty?
      redirect_to location: "/docs/v1.4.1/#{path}", status: 301
    else
      redirect_to location: "/docs", status: 301
    end
  end

  def granite
    redirect_to location: "/docs/v1.4.1/guides/models/granite", status: 301
  end
end
