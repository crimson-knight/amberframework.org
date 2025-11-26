# Service to auto-discover and scan documentation markdown files
# Supports versioned documentation with inheritance

module DocsScanner
  extend self

  DOCS_ROOT = "docs"

  # Cache structure: version_id => pages
  @@version_pages : Hash(String, Array(DocPage)) = {} of String => Array(DocPage)
  @@version_nav_trees : Hash(String, Array(NavItem)) = {} of String => Array(NavItem)

  # Scan all markdown files for a specific version
  # Includes inherited pages from parent versions
  def scan_version(version_id : String) : Array(DocPage)
    return @@version_pages[version_id] if @@version_pages.has_key?(version_id)

    version = DocVersionConfig.find(version_id)
    return [] of DocPage unless version

    # Get inheritance chain (most specific first)
    chain = DocVersionConfig.inheritance_chain(version_id)

    # Build merged page list: start with base, overlay with more specific
    # We need to track relative paths to handle overrides correctly
    pages_by_relative = {} of String => DocPage

    # Process chain in reverse (base first, then overlays)
    chain.reverse.each do |v|
      scan_folder(v.folder_path, v.id).each do |page|
        pages_by_relative[page.relative_path] = page
      end
    end

    # Convert to array and update URL paths for this version
    pages = pages_by_relative.values.map do |page|
      adjusted_page = page.dup

      # Extract the original version folder from the page's url_path
      original_version = page.url_path.split("/").first

      # Calculate path without the original version prefix
      url_without_version = if page.url_path == original_version
                              # This is the root index page (e.g., "v1" -> "")
                              ""
                            else
                              # Strip version prefix with slash (e.g., "v1/guides" -> "guides")
                              page.url_path.sub(/^#{Regex.escape(original_version)}\//, "")
                            end

      # Build new URL path with target version prefix
      adjusted_page.url_path = if url_without_version.empty?
                                 version_id
                               else
                                 "#{version_id}/#{url_without_version}"
                               end

      adjusted_page
    end

    # Sort by section and order
    pages.sort_by! { |p| {p.section, p.order, p.title} }

    @@version_pages[version_id] = pages
    pages
  end

  # Scan just the files in a specific folder (no inheritance)
  def scan_folder(folder_path : String, version_id : String) : Array(DocPage)
    pages = [] of DocPage

    return pages unless Dir.exists?(folder_path)

    Dir.glob("#{folder_path}/**/*.md").each do |file_path|
      # Skip SUMMARY.md, versions.yml
      next if file_path.ends_with?("SUMMARY.md")
      next if file_path.ends_with?("versions.yml")

      page = DocPage.from_file(file_path, version_id)
      pages << page if page
    end

    pages
  end

  # Get pages that exist ONLY in this version (not inherited)
  def scan_version_only(version_id : String) : Array(DocPage)
    version = DocVersionConfig.find(version_id)
    return [] of DocPage unless version

    scan_folder(version.folder_path, version_id)
  end

  # Build navigation tree for a version
  def build_nav_tree_for_version(version_id : String) : Array(NavItem)
    return @@version_nav_trees[version_id] if @@version_nav_trees.has_key?(version_id)

    pages = scan_version(version_id)
    version = DocVersionConfig.find(version_id)
    return [] of NavItem unless version

    # Get pages that are actually in this version (for badge detection)
    own_pages = scan_version_only(version_id)
    own_relative_paths = own_pages.map(&.relative_path).to_set

    # Check parent for changed vs new detection
    parent_relative_paths = Set(String).new
    if parent_id = version.inherits_from
      parent_pages = scan_version_only(parent_id)
      parent_relative_paths = parent_pages.map(&.relative_path).to_set
    end

    nav_tree = build_nav_tree(pages, version_id, own_relative_paths, parent_relative_paths)
    @@version_nav_trees[version_id] = nav_tree
    nav_tree
  end

  # Build navigation tree from pages
  private def build_nav_tree(
    pages : Array(DocPage),
    version_id : String,
    own_paths : Set(String),
    parent_paths : Set(String)
  ) : Array(NavItem)
    root_items = [] of NavItem
    section_map = {} of String => NavItem

    # First pass: create all section items and leaf items
    pages.each do |page|
      # Calculate badge for this page
      badge, badge_class = calculate_badge(page.relative_path, own_paths, parent_paths)

      if page.section.empty?
        # Root level item
        item = NavItem.new(page.title, page.url_path, page.order, page.is_section)
        item.set_badge(badge, badge_class)

        if page.is_section
          section_map[page.url_path] = item
        end
        root_items << item
      else
        # Need to ensure parent sections exist
        ensure_section_exists(page.section, section_map, root_items, pages, version_id)

        # Add this item to its parent section
        parent_key = find_section_key(page.section, section_map, version_id)
        if parent_key && (parent = section_map[parent_key]?)
          item = NavItem.new(page.title, page.url_path, page.order, page.is_section)
          item.set_badge(badge, badge_class)

          if page.is_section
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

  private def calculate_badge(relative_path : String, own_paths : Set(String), parent_paths : Set(String)) : {String?, String?}
    return {nil, nil} unless own_paths.includes?(relative_path)

    if parent_paths.includes?(relative_path)
      # Exists in both: Updated
      {"Updated", "badge-info"}
    else
      # Only in this version: New
      {"New", "badge-success"}
    end
  end

  private def find_section_key(section : String, section_map : Hash(String, NavItem), version_id : String) : String?
    # Try with version prefix
    versioned_path = "#{version_id}/#{section}"
    return versioned_path if section_map.has_key?(versioned_path)

    # Try without version prefix
    section_map.keys.find { |k| k.ends_with?("/#{section}") || k == section }
  end

  private def ensure_section_exists(
    section_path : String,
    section_map : Hash(String, NavItem),
    root_items : Array(NavItem),
    pages : Array(DocPage),
    version_id : String
  )
    parts = section_path.split("/")
    current_path = version_id

    parts.each_with_index do |part, i|
      parent_path = current_path
      current_path = "#{current_path}/#{part}"

      unless section_map.has_key?(current_path)
        # Find the page for this section or create a placeholder
        section_page = pages.find { |p| p.url_path == current_path && p.is_section }
        title = section_page ? section_page.title : part.capitalize
        order = section_page ? section_page.order : 100

        item = NavItem.new(title, current_path, order, true)
        section_map[current_path] = item

        if parent_path == version_id
          root_items << item
        elsif parent = section_map[parent_path]?
          parent.add_child(item)
        end
      end
    end
  end

  # Find a page by URL path within a version
  def find_page(version_id : String, url_path : String) : DocPage?
    pages = scan_version(version_id)
    normalized = url_path.strip("/")

    # Build full path with version prefix
    full_path = if normalized.empty? || normalized == version_id
                  version_id
                elsif normalized.starts_with?("#{version_id}/")
                  normalized
                else
                  "#{version_id}/#{normalized}"
                end

    # Try exact match first
    pages.find { |p| p.url_path == full_path } ||
      # Try with /index suffix for directory pages
      pages.find { |p| p.url_path == "#{full_path}/index" }
  end

  # Get breadcrumbs for a path within a version
  def breadcrumbs(version_id : String, url_path : String) : Array(NamedTuple(title: String, path: String))
    pages = scan_version(version_id)
    crumbs = [] of NamedTuple(title: String, path: String)

    # Remove version prefix from path for processing
    path_without_version = url_path.sub(/^#{Regex.escape(version_id)}\//, "")
    parts = path_without_version.split("/").reject(&.empty?)

    current_path = version_id

    parts.each do |part|
      current_path = "#{current_path}/#{part}"
      if page = pages.find { |p| p.url_path == current_path }
        crumbs << {title: page.title, path: current_path}
      end
    end

    crumbs
  end

  # Get previous and next pages for navigation within a version
  def prev_next(version_id : String, url_path : String) : {DocPage?, DocPage?}
    pages = scan_version(version_id)

    # Get flat list of pages in navigation order, excluding root index
    flat_pages = pages.reject { |p| p.url_path == version_id }.sort_by { |p| {p.section, p.order} }

    # Build full path if needed
    full_path = if url_path.starts_with?("#{version_id}/") || url_path == version_id
                  url_path
                else
                  "#{version_id}/#{url_path}"
                end

    current_index = flat_pages.index { |p| p.url_path == full_path }

    return {nil, nil} unless current_index

    prev_page = current_index > 0 ? flat_pages[current_index - 1] : nil
    next_page = current_index < flat_pages.size - 1 ? flat_pages[current_index + 1] : nil

    {prev_page, next_page}
  end

  # Check which version a file belongs to (where it actually exists)
  def source_version(version_id : String, relative_path : String) : String?
    chain = DocVersionConfig.inheritance_chain(version_id)

    chain.each do |v|
      file_path = File.join(v.folder_path, relative_path)
      return v.id if File.exists?(file_path)
    end

    nil
  end

  # Get list of files that are new or changed in a version
  def changed_files(version_id : String) : Array(NamedTuple(path: String, status: String))
    version = DocVersionConfig.find(version_id)
    return [] of NamedTuple(path: String, status: String) unless version

    own_pages = scan_version_only(version_id)
    parent_paths = Set(String).new

    if parent_id = version.inherits_from
      parent_pages = scan_version_only(parent_id)
      parent_paths = parent_pages.map(&.relative_path).to_set
    end

    own_pages.map do |page|
      status = parent_paths.includes?(page.relative_path) ? "updated" : "new"
      {path: page.relative_path, status: status}
    end
  end

  # Clear all caches (useful for development/testing)
  def clear_cache
    @@version_pages.clear
    @@version_nav_trees.clear
  end

  # Backward compatibility: scan_all returns default version pages
  def scan_all : Array(DocPage)
    scan_version(DocVersionConfig.default.id)
  end

  # Backward compatibility: build_nav_tree
  def build_nav_tree(pages : Array(DocPage)) : Array(NavItem)
    build_nav_tree_for_version(DocVersionConfig.default.id)
  end
end
