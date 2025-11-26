require "../models/doc_page"
require "../models/doc_version"
require "../services/docs_scanner"
require "../services/markdown_preprocessor"

class DocsController < ApplicationController
  # Use standard application layout (same as blog)
  LAYOUT = "application.slang"

  # Instance variable type annotations
  @path : String = ""
  @page : DocPage? = nil
  @nav_tree : Array(NavItem) = [] of NavItem
  @breadcrumbs : Array(NamedTuple(title: String, path: String)) = [] of NamedTuple(title: String, path: String)
  @prev_page : DocPage? = nil
  @next_page : DocPage? = nil

  # Version-related instance variables
  @version : DocVersion? = nil
  @version_id : String = ""
  @all_versions : Array(DocVersion) = [] of DocVersion
  @is_inherited : Bool = false
  @page_badge : String? = nil
  @page_badge_class : String? = nil

  # Root /docs - redirect to default version
  def index
    default_version = DocVersionConfig.default
    redirect_to location: "/docs/#{default_version.id}", status: 302
  end

  # Handle /docs/*path - could be version index or versioned page
  def show
    full_path = params["path"].as(String)
    path_parts = full_path.split("/", 2)

    # Check if first part is a version
    potential_version = path_parts[0]

    if DocVersionConfig.valid?(potential_version)
      @version_id = potential_version
      @path = path_parts.size > 1 ? path_parts[1] : ""
    else
      # No version specified, use default and treat entire path as page path
      @version_id = DocVersionConfig.default.id
      @path = full_path
      # Redirect to versioned URL for consistency
      redirect_to location: "/docs/#{@version_id}/#{@path}", status: 302
      return
    end

    @version = DocVersionConfig.find(@version_id)
    @all_versions = DocVersionConfig.all

    unless @version
      raise Amber::Exceptions::RouteNotFound.new(request)
    end

    # Find page using version-aware scanner
    @page = DocsScanner.find_page(@version_id, @path)
    @nav_tree = DocsScanner.build_nav_tree_for_version(@version_id)
    @breadcrumbs = DocsScanner.breadcrumbs(@version_id, "#{@version_id}/#{@path}")

    prev_page, next_page = DocsScanner.prev_next(@version_id, @path)
    @prev_page = prev_page
    @next_page = next_page

    # Calculate page badge (new/updated)
    if @page
      calculate_page_badge
    end

    if @page
      render("show.slang")
    else
      raise Amber::Exceptions::RouteNotFound.new(request)
    end
  end

  # API endpoint to get changed files for a version (useful for changelog)
  def changes
    version_id = params["version"]?.to_s
    unless DocVersionConfig.valid?(version_id)
      return respond_with do
        json({error: "Invalid version"}.to_json)
      end
    end

    changes = DocsScanner.changed_files(version_id)
    respond_with do
      json(changes.to_json)
    end
  end

  # Return raw markdown content (for Copy Page feature)
  def raw
    full_path = params["path"].as(String)
    path_parts = full_path.split("/", 2)

    potential_version = path_parts[0]

    if DocVersionConfig.valid?(potential_version)
      version_id = potential_version
      page_path = path_parts.size > 1 ? path_parts[1] : ""
    else
      version_id = DocVersionConfig.default.id
      page_path = full_path
    end

    page = DocsScanner.find_page(version_id, page_path)

    if page
      response.content_type = "text/plain; charset=utf-8"
      response.headers["Content-Disposition"] = "inline"
      page.content
    else
      response.status_code = 404
      "Page not found"
    end
  end

  private def calculate_page_badge
    return unless page = @page
    return unless version = @version

    # For base versions (no inheritance), don't show any badges
    # Everything would be "new" which is meaningless
    return unless version.inherits_from

    # Check if page exists in this version's folder
    own_pages = DocsScanner.scan_version_only(@version_id)
    own_paths = own_pages.map(&.relative_path).to_set

    unless own_paths.includes?(page.relative_path)
      @is_inherited = true
      return
    end

    # Check parent version
    if parent_id = version.inherits_from
      parent_pages = DocsScanner.scan_version_only(parent_id)
      parent_paths = parent_pages.map(&.relative_path).to_set

      if parent_paths.includes?(page.relative_path)
        @page_badge = "Updated"
        @page_badge_class = "badge-info"
      else
        @page_badge = "New"
        @page_badge_class = "badge-success"
      end
    end
  end

  # Helper to render markdown with preprocessing
  def render_markdown(content : String) : String
    processed = MarkdownPreprocessor.process(content)
    Markd.to_html(processed)
  end

  # Helper to get URL for a page in a different version
  def version_url(target_version : String, current_path : String) : String
    # Strip current version from path
    path_without_version = current_path.sub(/^#{Regex.escape(@version_id)}\//, "")
    "/docs/#{target_version}/#{path_without_version}".sub(/\/$/, "")
  end
end
