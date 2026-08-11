Amber::Server.configure do |app|
  pipeline :web do
    # Plug is the method to use connect a pipe (middleware)
    # A plug accepts an instance of HTTP::Handler
    plug Amber::Pipe::PoweredByAmber.new
    plug Amber::Pipe::Error.new
    plug Amber::Pipe::Logger.new
    plug Amber::Pipe::CSRF.new
  end

  # All static content will run these transformations
  pipeline :static do
    plug Amber::Pipe::Error.new
    plug Amber::Pipe::Static.new("./public")
  end

  pipeline :api do
    plug Amber::Pipe::PoweredByAmber.new
    plug Amber::Pipe::Error.new
    plug Amber::Pipe::Logger.new
  end

  routes :web do
    websocket "/ws", SiteSocket
    get "/index.md", HomeController, :page_markdown
    get "/media.md", HomeController, :page_markdown
    get "/characters.md", HomeController, :page_markdown
    get "/showcase.md", HomeController, :page_markdown
    get "/sponsors.md", HomeController, :page_markdown
    get "/releases.md", HomeController, :page_markdown
    get "/performance.md", HomeController, :page_markdown
    get "/amber-way.md", HomeController, :page_markdown
    get "/privacy.md", HomeController, :page_markdown
    get "/blog.md", BlogController, :index_markdown
    get "/blog/feed", BlogController, :feed
    get "/blog/feed.xml", BlogController, :feed
    get "/rss", BlogController, :feed

    # Amber normalizes the built-in JSON extension before matching, so each
    # base action inspects the original request path. Markdown is registered
    # explicitly because beta.2 does not yet include it as a responder type.
    get "/", HomeController, :index
    get "/index", HomeController, :index
    get "/media", HomeController, :media
    get "/characters", HomeController, :characters
    get "/characters/:id", HomeController, :character
    get "/showcase", HomeController, :showcase
    get "/sponsors", HomeController, :sponsors
    get "/releases", HomeController, :releases
    get "/performance", HomeController, :performance
    get "/amber-way", HomeController, :amber_way
    get "/privacy", HomeController, :privacy
    get "/blog", BlogController, :index
    get "/blog/:year/:month/:day/:id", BlogController, :show

    # Documentation routes (served locally, versioned)
    get "/docs", DocsController, :index
    get "/docs/v2/knowledge.md", DocsController, :knowledge
    get "/docs/raw/*path", DocsController, :raw
    get "/docs/*path", DocsController, :show

    # Documentation API (for changelog/diff features)
    get "/api/docs/changes/:version", DocsController, :changes

    # Legacy redirects for backward compatibility
    get "/guides/*path", HomeController, :legacy_guides_redirect
    get "/amber/*path", HomeController, :amber
    get "/granite/*", HomeController, :granite
    get "/recipes/*", HomeController, :examples
    get "/getting-started/*", HomeController, :getting_started
  end

  routes :api do
    get "/mcp", McpController, :show
    post "/mcp", McpController, :handle
  end

  routes :static do
    # Each route is defined as follow
    # verb resource : String, controller : Symbol, action : Symbol
    get "/*", Amber::Controller::Static, :index
  end
end
