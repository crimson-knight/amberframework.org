require "../spec_helper"

describe DocsScanner do
  # Clear cache before each test to ensure clean state
  before_each do
    DocsScanner.clear_cache
  end

  describe ".scan_version" do
    it "returns pages for a valid version" do
      pages = DocsScanner.scan_version("v1.4.1")
      pages.should_not be_empty
    end

    it "returns empty array for invalid version" do
      pages = DocsScanner.scan_version("invalid-version")
      pages.should be_empty
    end

    it "caches results for subsequent calls" do
      # First call populates cache
      pages1 = DocsScanner.scan_version("v1.4.1")
      # Second call should return same object
      pages2 = DocsScanner.scan_version("v1.4.1")
      pages1.object_id.should eq pages2.object_id
    end
  end

  describe ".knowledge_bundle" do
    it "combines the published V2 pages with canonical source links" do
      bundle = DocsScanner.knowledge_bundle("v2")

      bundle.should contain("# Amber Framework 2.0 Beta documentation")
      bundle.should contain("## Web Template")
      bundle.should contain("https://amberframework.org/docs/v2/guides/web-template")
      bundle.should contain("## Build a Pet Tracker")
      bundle.should contain("Prefer V2-authored pages")
    end
  end

  describe ".deleted_paths" do
    it "returns deleted paths for v2" do
      deleted = DocsScanner.deleted_paths("v2")
      deleted.should_not be_empty
    end

    it "includes legacy CLI paths in v2 deletions" do
      deleted = DocsScanner.deleted_paths("v2")
      deleted.includes?("cli/recipes.md").should be_true
      deleted.includes?("cli/index.md").should be_false
      deleted.includes?("cli/new.md").should be_false
      deleted.includes?("cli/generate.md").should be_false
      deleted.includes?("cli/watch.md").should be_false
    end

    it "includes Granite paths in v2 deletions" do
      deleted = DocsScanner.deleted_paths("v2")
      deleted.includes?("guides/models/granite/index.md").should be_true
    end

    it "includes Jennifer paths in v2 deletions" do
      deleted = DocsScanner.deleted_paths("v2")
      deleted.includes?("guides/models/jennifer/index.md").should be_true
    end

    it "returns empty set for version without deletions" do
      deleted = DocsScanner.deleted_paths("v1.4.1")
      deleted.should be_empty
    end

    it "links retired ORM pages to their V2 Grant replacements" do
      DocsScanner.replacement_path("v2", "guides/models/granite/querying.md").should eq("guides/models/grant/queries")
      DocsScanner.replacement_path("v2", "guides/models/jennifer/models.md").should eq("guides/models/grant/basics")
    end

    it "links stale V1 project instructions to reviewed V2 guides" do
      DocsScanner.replacement_path("v2", "guides/docker.md").should eq("deployment")
      DocsScanner.find_page("v2", "guides/views").should_not be_nil
      DocsScanner.replacement_path("v2", "guides/controllers/params.md").should eq("guides/schema-api")
    end
  end

  describe "V2 publication boundaries" do
    it "includes the published V2 CLI pages" do
      pages = DocsScanner.scan_version("v2")
      cli_pages = pages.select { |p| p.url_path.includes?("cli/") }
      cli_pages.map(&.url_path).should contain("v2/cli/new")
      cli_pages.map(&.url_path).should contain("v2/cli/generate")
      cli_pages.map(&.url_path).should contain("v2/cli/watch")
    end

    it "does include CLI pages in v1.4.1" do
      pages = DocsScanner.scan_version("v1.4.1")
      cli_pages = pages.select { |p| p.url_path.includes?("cli/") }
      cli_pages.should_not be_empty
    end

    it "does not include deleted Granite pages in v2" do
      pages = DocsScanner.scan_version("v2")
      granite_pages = pages.select { |p| p.url_path.includes?("guides/models/granite") }
      granite_pages.should be_empty
    end

    it "does include Granite pages in v1.4.1" do
      pages = DocsScanner.scan_version("v1.4.1")
      granite_pages = pages.select { |p| p.url_path.includes?("guides/models/granite") }
      granite_pages.should_not be_empty
    end

    it "does not include deleted Jennifer pages in v2" do
      pages = DocsScanner.scan_version("v2")
      jennifer_pages = pages.select { |p| p.url_path.includes?("guides/models/jennifer") }
      jennifer_pages.should be_empty
    end

    it "publishes V2-reviewed controller essentials" do
      v2_pages = DocsScanner.scan_version_only("v2")
      v2_pages.map(&.url_path).should contain("v2/guides/controllers/request-and-response-objects")
      v2_pages.map(&.url_path).should contain("v2/guides/controllers/sessions")
    end

    it "publishes authored and inherited pages while retaining V2 overrides" do
      published_paths = DocsScanner.scan_version("v2").map(&.relative_path).sort
      authored_paths = DocsScanner.scan_version_only("v2").map(&.relative_path).sort
      published_paths.size.should be > authored_paths.size
      authored_paths.each { |path| published_paths.should contain(path) }
    end

    it "does not carry known V1-only toolchain instructions into V2" do
      own_paths = DocsScanner.scan_version_only("v2").map(&.relative_path).to_set
      stale_pattern = /\b(granite|jennifer|webpack|node\.js|npm|yarn|amber encrypt|amber routes|amber exec|amber database|redis|slang|kilt|heroku|dokku|digitalocean|digital ocean)\b/i

      DocsScanner.scan_version("v2").reject { |page| own_paths.includes?(page.relative_path) }.each do |page|
        page.content.should_not match(stale_pattern), "#{page.relative_path} contains known V1-only instructions"
      end
    end
  end

  describe ".find_page" do
    it "finds pages in v1.4.1" do
      page = DocsScanner.find_page("v1.4.1", "guides/installation")
      page.should_not be_nil
    end

    it "finds pages in v2" do
      page = DocsScanner.find_page("v2", "getting-started")
      page.should_not be_nil
    end

    it "finds every published V2 CLI guide" do
      ["cli", "cli/new", "cli/generate", "cli/watch"].each do |path|
        DocsScanner.find_page("v2", path).should_not be_nil
      end
    end

    it "returns nil for a legacy CLI page deleted in v2" do
      DocsScanner.find_page("v2", "cli/recipes").should be_nil
    end

    it "finds deleted pages in v1.4.1" do
      page = DocsScanner.find_page("v1.4.1", "cli")
      page.should_not be_nil
    end
  end

  describe ".build_nav_tree_for_version" do
    it "builds navigation tree for v1.4.1" do
      nav = DocsScanner.build_nav_tree_for_version("v1.4.1")
      nav.should_not be_empty
    end

    it "builds navigation tree for v2" do
      nav = DocsScanner.build_nav_tree_for_version("v2")
      nav.should_not be_empty
    end

    it "v2 nav tree contains the published CLI section and commands" do
      nav = DocsScanner.build_nav_tree_for_version("v2")
      cli_item = nav.find { |item| item.path == "v2/cli" }
      cli_item.should_not be_nil

      if cli_item
        cli_item.children.map(&.path).should eq([
          "v2/cli/new",
          "v2/cli/generate",
          "v2/cli/watch",
        ])
      end
    end

    it "labels reviewed pages and leaves unchanged inherited pages unbadged" do
      pending_items = DocsScanner.build_nav_tree_for_version("v2").dup
      reviewed_item : NavItem? = nil
      inherited_item : NavItem? = nil

      until pending_items.empty?
        item = pending_items.shift
        if item.path == "v2/guides/controllers/request-and-response-objects"
          reviewed_item = item
        elsif item.path == "v2/guides/controllers/cookies"
          inherited_item = item
        end
        pending_items.concat(item.children)
      end

      reviewed_item.should_not be_nil
      reviewed_item.try(&.badge).should eq("Updated")
      reviewed_item.try(&.badge_class).should eq("badge-info")
      inherited_item.should_not be_nil
      inherited_item.try(&.badge).should be_nil
      inherited_item.try(&.badge_class).should be_nil
    end

    it "every V2 navigation target resolves to an authored page" do
      pending_items = DocsScanner.build_nav_tree_for_version("v2").dup

      until pending_items.empty?
        item = pending_items.shift
        page_path = item.path.sub(/^v2\/?/, "")
        DocsScanner.find_page("v2", page_path).should_not be_nil, "missing navigation page #{item.path}"
        pending_items.concat(item.children)
      end
    end

    it "v1.4.1 nav tree contains CLI section" do
      nav = DocsScanner.build_nav_tree_for_version("v1.4.1")
      titles = nav.map(&.title).join(", ").downcase
      titles.should contain("cli")
    end
  end

  describe ".clear_cache" do
    it "clears all caches" do
      # Populate caches
      DocsScanner.scan_version("v1.4.1")
      DocsScanner.build_nav_tree_for_version("v1.4.1")
      DocsScanner.deleted_paths("v2")

      # Clear
      DocsScanner.clear_cache

      # After clearing, next call should return fresh data
      # We can verify by checking object_id changes
      pages1 = DocsScanner.scan_version("v1.4.1")
      DocsScanner.clear_cache
      pages2 = DocsScanner.scan_version("v1.4.1")

      # After cache clear, should get new object
      pages1.object_id.should_not eq pages2.object_id
    end
  end
end
