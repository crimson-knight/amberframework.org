module SiteContent
  extend self

  alias Page = NamedTuple(title: String, description: String, sections: Array(String))

  PAGES = {
    "index" => {
      title:       "Amber Framework",
      description: "A productive, type-safe web framework for Crystal with server-rendered ECR, local browser assets, WebSockets, jobs, and an explicit application structure.",
      sections:    [
        "## Start with the supported web path\nInstall Amber CLI 2.0.3, run `amber new my_app`, enter the generated directory, run `crystal spec`, and start `amber watch`.",
        "## A complete first-party baseline\nRoutes, controllers, ECR views, typed configuration, schemas, local CSS, browser-native ES modules, WebSockets, and background jobs fit one inspectable application shape. Amber 2.0.0-beta.2 applications must keep job work stealing disabled until the corrected request counter appears in a later tag.",
        "## Measured performance\nOn July 17, 2026, the current JSON path sustained a 21,795 req/s hosted median on a DigitalOcean Basic one-vCPU, 512 MB-class target across a mixed 1,000-route workload.",
        "## The website under load\nOn August 11, 2026, this release candidate's complete homepage sustained a 5,907 req/s median on the smallest target. It held 1,000 joined WebSocket clients with zero connection errors while the rendered JSON path sustained an 8,058 req/s median in that stage. The published evidence records the noisy sequential-stage boundary.",
      ],
    },
    "media" => {
      title:       "Amber brand resources",
      description: "The public logos, character marks, colors, typography, components, and usage boundaries for Amber Framework.",
      sections:    [
        "## Brand system\nAmber uses warm paper surfaces, orange crystal accents, expressive serif display type, readable sans-serif text, and playful original-studio crew illustration.",
        "## Usage\nKeep marks legible, preserve clear space, do not redraw the crystal, and do not use contributor or crew art to imply an endorsement that did not happen.",
      ],
    },
    "characters" => {
      title:       "The Amber crew",
      description: "Characters map memorable names to real software responsibilities and release boundaries.",
      sections:    [
        "## Amber\nThe framework lead owns routing, controllers, ECR views, configuration, schemas, WebSockets, jobs, and application structure.",
        "## Grant\nThe records specialist names the optional relational persistence ecosystem path.",
        "## Gemma\nThe files specialist names the optional attachment validation, storage, and delivery path.",
      ],
    },
    "showcase" => {
      title:       "Built with Amber",
      description: "Open applications that demonstrate Amber's supported architecture and performance-minded deployment model.",
      sections:    [
        "## Amberframework.org\nThis public website is an Amber V2 application using controllers, ECR, local CSS, a browser-native import map, Markdown documentation, JSON endpoints, and no front-end framework or bundler.",
        "## Submit a project\nPublic showcase entries need a working URL, an inspectable Amber implementation or technical write-up, and honest release and support boundaries.",
      ],
    },
    "sponsors" => {
      title:       "Sponsors and contributors",
      description: "The people and organizations contributing engineering, infrastructure, documentation, and funding to Amber Framework.",
      sections:    [
        "## Primary sponsor\nAgentC supports the current Amber V2 engineering, documentation, release, and infrastructure work.",
        "## Contributors\nAmber is built by maintainers and community contributors across the framework, CLI, documentation, adapters, and ecosystem projects.",
      ],
    },
    "releases" => {
      title:       "Amber releases",
      description: "Dated Amber Framework and Amber CLI releases synchronized from GitHub, with the V2 web beta boundary explained in plain language.",
      sections:    [
        "## Current choices\nAmber Framework 1.5.0 is the stable maintenance line, Amber Framework 2.0.0-beta.2 is the current V2 web-framework beta, and Amber CLI 2.0.3 is the current standalone application generator.",
        "## What beta means\nThe V2 tag is a prerelease while its web path is tested in public. The release-gated web core is coherent today; persistence, files, native output, and Asset Pipeline are separately labeled preview surfaces rather than evidence that ordinary routes, controllers, or ECR views are expected to be rewritten.",
        "## Source of truth\nGitHub Releases remains the source of truth. The human page is refreshed from the Amber Framework and Amber CLI repositories every six hours and links every entry back to its original release.",
      ],
    },
    "performance" => {
      title:       "Amber performance evidence",
      description: "Human-readable Amber V2 performance results, workloads, limitations, and reproducible source data.",
      sections:    [
        "## The public website\nOn August 11, 2026, the complete 26,271-byte Amber homepage sustained a 5,906.72 req/s median on a DigitalOcean Basic one-vCPU, 512 MB-class target. The same lab held 1,000 joined WebSocket clients with zero connection errors.",
        "## The framework request path\nOn July 17, 2026, an Amber V2 mixed 1,000-route JSON workload sustained a 21,795 req/s hosted median on the same server class across seven rotating repetitions with zero socket and non-2xx errors.",
        "## Read the boundary\nThese results describe exact workloads, not an SLA or a promise for database-backed applications. The WebSocket clients were idle after joining, and its sequential shared-vCPU stages were noisy rather than a causal scaling curve.",
      ],
    },
    "privacy" => {
      title:       "Privacy",
      description: "How the Amber Framework website handles visitor data.",
      sections:    [
        "## No application tracking\nThe site does not set application cookies, run analytics, or load an advertising tracker.",
        "## Infrastructure logs\nThe hosting and network layers may retain ordinary operational request logs for security, reliability, and abuse prevention according to their configured retention policies.",
      ],
    },
    "amber-way" => {
      title:       "Amber's Way",
      description: "Amber's shared values and concrete coding beliefs.",
      sections:    [
        "## Shared values\nProductivity, performance, happiness, humility, respect, and trust guide both the framework and its community.",
        "## Coding beliefs\nOne action should declare honest representations; ECR owns HTML; the filesystem teaches the application; local web-platform features come first; channels update live pages; jobs move slow work off requests; performance claims carry their workload. Beta.2 keeps work stealing disabled until the corrected request counter is tagged.",
      ],
    },
    "amber" => {
      title:       "Amber — framework lead",
      description: "Amber personifies the framework core and the supported web application path.",
      sections:    ["## Responsibility\nRouting, controllers, ECR views, configuration, schemas, WebSockets, jobs, and the application structure that connects them."],
    },
    "grant" => {
      title:       "Grant — records",
      description: "Grant personifies relational models, migrations, associations, validation, and queries.",
      sections:    ["## Release boundary\nGrant is an optional ecosystem preview, not a dependency of the supported clean web template."],
    },
    "gemma" => {
      title:       "Gemma — files",
      description: "Gemma personifies attachment validation, storage, metadata, and delivery.",
      sections:    ["## Release boundary\nGemma is an optional ecosystem preview, not a dependency of the supported clean web template."],
    },
  } of String => Page

  def find(slug : String) : Page?
    PAGES[slug]?
  end

  def markdown(slug : String, canonical_path : String) : String?
    page = find(slug)
    return unless page

    String.build do |text|
      text << "# #{page[:title]}\n\n"
      text << page[:description] << "\n\n"
      text << "Canonical page: https://amberframework.org#{canonical_path}\n\n"
      page[:sections].each { |section| text << section << "\n\n" }
    end
  end

  def json(slug : String, canonical_path : String) : String?
    page = find(slug)
    return unless page

    {
      title:         page[:title],
      description:   page[:description],
      canonical_url: "https://amberframework.org#{canonical_path}",
      markdown_url:  "https://amberframework.org#{canonical_path == "/" ? "/index" : canonical_path}.md",
      sections:      page[:sections],
    }.to_json
  end
end
