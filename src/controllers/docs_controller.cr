require "../models/doc_page"
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

  # Cache docs at class level (similar to BlogController)
  @@pages : Array(DocPage)? = nil
  @@nav_tree : Array(NavItem)? = nil

  def index
    @path = ""
    @page = find_page("")
    @nav_tree = nav_tree
    @breadcrumbs = [] of NamedTuple(title: String, path: String)
    prev_page, next_page = DocsScanner.prev_next(pages, "")
    @prev_page = prev_page
    @next_page = next_page

    if @page
      render("show.slang")
    else
      raise Amber::Exceptions::RouteNotFound.new(request)
    end
  end

  def show
    @path = params["path"].as(String)
    @page = find_page(@path)
    @nav_tree = nav_tree
    @breadcrumbs = DocsScanner.breadcrumbs(pages, @path)
    prev_page, next_page = DocsScanner.prev_next(pages, @path)
    @prev_page = prev_page
    @next_page = next_page

    if @page
      render("show.slang")
    else
      raise Amber::Exceptions::RouteNotFound.new(request)
    end
  end

  private def pages : Array(DocPage)
    @@pages ||= DocsScanner.scan_all
  end

  private def nav_tree : Array(NavItem)
    @@nav_tree ||= DocsScanner.build_nav_tree(pages)
  end

  private def find_page(path : String) : DocPage?
    DocsScanner.find_page(pages, path)
  end

  # Helper to render markdown with preprocessing
  def render_markdown(content : String) : String
    processed = MarkdownPreprocessor.process(content)
    Markd.to_html(processed)
  end
end
