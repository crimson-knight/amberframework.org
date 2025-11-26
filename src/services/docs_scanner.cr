# Service to auto-discover and scan documentation markdown files

module DocsScanner
  extend self

  DOCS_ROOT = "docs"

  # Scan all markdown files in the docs directory
  def scan_all : Array(DocPage)
    pages = [] of DocPage

    Dir.glob("#{DOCS_ROOT}/**/*.md").each do |file_path|
      # Skip SUMMARY.md as it's just for reference
      next if file_path.ends_with?("SUMMARY.md")

      page = DocPage.from_file(file_path)
      pages << page if page
    end

    # Sort by section and then by order
    pages.sort_by! { |p| {p.section, p.order, p.title} }
    pages
  end

  # Build navigation tree from scanned pages
  def build_nav_tree(pages : Array(DocPage)) : Array(NavItem)
    root_items = [] of NavItem
    section_map = {} of String => NavItem

    # First pass: create all section items and leaf items
    pages.each do |page|
      if page.section.empty?
        # Root level item
        item = NavItem.new(page.title, page.url_path, page.order, page.is_section)
        if page.is_section
          section_map[page.url_path] = item
        end
        root_items << item
      else
        # Need to ensure parent sections exist
        ensure_section_exists(page.section, section_map, root_items, pages)

        # Add this item to its parent section
        parent_key = page.section
        if parent = section_map[parent_key]?
          item = NavItem.new(page.title, page.url_path, page.order, page.is_section)
          if page.is_section
            # This is a subsection, register it
            section_map[page.url_path] = item
          end
          parent.add_child(item)
        end
      end
    end

    # Sort root items
    root_items.sort_by! { |i| i.order }
    root_items
  end

  private def self.ensure_section_exists(section_path : String, section_map : Hash(String, NavItem), root_items : Array(NavItem), pages : Array(DocPage))
    parts = section_path.split("/")
    current_path = ""

    parts.each_with_index do |part, i|
      parent_path = current_path
      current_path = current_path.empty? ? part : "#{current_path}/#{part}"

      unless section_map.has_key?(current_path)
        # Find the page for this section or create a placeholder
        section_page = pages.find { |p| p.url_path == current_path && p.is_section }
        title = section_page ? section_page.title : part.capitalize
        order = section_page ? section_page.order : 100

        item = NavItem.new(title, current_path, order, true)
        section_map[current_path] = item

        if parent_path.empty?
          root_items << item
        elsif parent = section_map[parent_path]?
          parent.add_child(item)
        end
      end
    end
  end

  # Find a page by URL path
  def find_page(pages : Array(DocPage), url_path : String) : DocPage?
    # Normalize path
    normalized = url_path.strip("/")

    # Try exact match first
    pages.find { |p| p.url_path == normalized } ||
      # Try with /index suffix for directory pages
      pages.find { |p| p.url_path == "#{normalized}/index" } ||
      # For empty path, find the root index
      (normalized.empty? ? pages.find { |p| p.url_path.empty? || p.url_path == "index" } : nil)
  end

  # Get breadcrumbs for a given path
  def breadcrumbs(pages : Array(DocPage), url_path : String) : Array(NamedTuple(title: String, path: String))
    crumbs = [] of NamedTuple(title: String, path: String)

    parts = url_path.split("/").reject(&.empty?)
    current_path = ""

    parts.each do |part|
      current_path = current_path.empty? ? part : "#{current_path}/#{part}"
      if page = pages.find { |p| p.url_path == current_path }
        crumbs << {title: page.title, path: current_path}
      end
    end

    crumbs
  end

  # Get previous and next pages for navigation
  def prev_next(pages : Array(DocPage), url_path : String) : {DocPage?, DocPage?}
    # Get flat list of pages in navigation order
    flat_pages = pages.reject { |p| p.url_path.empty? }.sort_by { |p| {p.section, p.order} }

    current_index = flat_pages.index { |p| p.url_path == url_path }

    return {nil, nil} unless current_index

    prev_page = current_index > 0 ? flat_pages[current_index - 1] : nil
    next_page = current_index < flat_pages.size - 1 ? flat_pages[current_index + 1] : nil

    {prev_page, next_page}
  end
end
