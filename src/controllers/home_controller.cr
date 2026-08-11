class HomeController < ApplicationController
  AMBER_WAY_VALUES = [
    {
      number: "01",
      slug:   "productivity",
      title:  "Productivity.",
      copy:   "Use conventions, generators, and one coherent application structure to remove routine decisions. The goal is to move from an idea to useful software without spending the first week assembling a framework.",
    },
    {
      number: "02",
      slug:   "performance",
      title:  "Performance.",
      copy:   "Build on Crystal's type system, native compilation, concurrency, and macros. Performance should be part of the framework's architecture—not a tax the application team pays after the product succeeds.",
    },
    {
      number: "03",
      slug:   "happiness",
      title:  "Happiness.",
      copy:   "Make everyday web development simple, comfortable, and understandable. Clear errors, readable defaults, useful diagnostics, and fast feedback protect the attention that developers need for their actual product.",
    },
    {
      number: "04",
      slug:   "humility",
      title:  "Humility.",
      copy:   "Amber is not the center of the universe. Borrow ideas that have been tested elsewhere, acknowledge incomplete work, invite correction, and stay open to better answers from Crystal and the wider web community.",
    },
    {
      number: "05",
      slug:   "respect",
      title:  "Respect.",
      copy:   "Treat contributors and users as people whose time matters. Document the path, preserve stable references, explain breaking changes, and design defaults that do not surprise the next person maintaining the application.",
    },
    {
      number: "06",
      slug:   "trust",
      title:  "Trust.",
      copy:   "Build code and processes that another developer—or coding agent—can understand and safely extend. Share context, keep responsibilities explicit, and let capable collaborators drive when they are closest to the problem.",
    },
  ]

  AMBER_WAY_CODING_BELIEFS = [
    {
      slug:    "representations",
      title:   "One action, honest representations",
      summary: "A controller action should load the resource once, then use respond_with to make the available HTML and JSON representations explicit.",
    },
    {
      slug:    "views",
      title:   "Views own HTML",
      summary: "Controllers coordinate; ECR templates express the document. Shared layouts and partials keep the HTML boundary visible and testable.",
    },
    {
      slug:    "project-shape",
      title:   "The filesystem teaches the application",
      summary: "Routes, controllers, views, public assets, and request specs have stable homes so a new collaborator can predict where behavior lives.",
    },
    {
      slug:    "web-platform",
      title:   "Use the web platform first",
      summary: "Local CSS, browser-native modules, and an import map provide a complete front end without requiring npm, a bundler, a UI framework, or a CDN.",
    },
    {
      slug:    "measured-performance",
      title:   "Performance claims carry their workload",
      summary: "Amber publishes the hardware, request mix, repetitions, errors, and limits beside a result so a benchmark remains evidence instead of mythology.",
    },
  ]

  def index
    render("index.ecr")
  end

  def media
    render("media.ecr")
  end

  def characters
    render("characters.ecr")
  end

  def character
    unless {"amber", "grant", "gemma"}.includes?(params["id"])
      raise Amber::Exceptions::RouteNotFound.new(request)
    end

    render("character.ecr")
  end

  def amber_way
    values = AMBER_WAY_VALUES
    coding_beliefs = AMBER_WAY_CODING_BELIEFS
    benchmark = {
      measured_at:                 "2026-07-17",
      median_requests_per_second:  21_795,
      target:                      "DigitalOcean Basic 1 vCPU, 512 MB class",
      routes:                      1_000,
      connections:                 16,
      repetitions:                 7,
      successful_matrix_responses: 18_728_053,
      socket_errors:               0,
      non_2xx_responses:           0,
      evidence:                    "/benchmarks/amber-v2-round22-summary.json",
    }
    page = {
      title:          "Amber's Way",
      values:         values,
      coding_beliefs: coding_beliefs,
      benchmark:      benchmark,
    }

    context.response.headers["Vary"] = "Accept"
    respond_with do
      html { render("amber_way.ecr") }
      json { page.to_json }
    end
  end

  def privacy
    render("privacy.ecr")
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
