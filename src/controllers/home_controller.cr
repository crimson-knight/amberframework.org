class HomeController < ApplicationController
  def index
    render("index.slang")
  end

  def media
    render("media.slang")
  end

  def guides
    redirect_to location: "/docs", status: 302
  end

  def legacy_guides_redirect
    path = params["path"]?
    if path && !path.to_s.empty?
      redirect_to location: "/docs/guides/#{path}", status: 301
    else
      redirect_to location: "/docs/guides", status: 301
    end
  end

  def getting_started
    redirect_to location: "/docs/getting-started", status: 301
  end

  def examples
    redirect_to location: "/docs/examples", status: 301
  end

  def amber
    path = params["path"]?
    if path && !path.to_s.empty?
      redirect_to location: "/docs/#{path}", status: 301
    else
      redirect_to location: "/docs", status: 301
    end
  end

  def granite
    redirect_to location: "/docs/guides/models/granite", status: 301
  end
end
