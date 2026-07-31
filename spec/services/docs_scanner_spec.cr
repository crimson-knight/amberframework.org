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

  describe ".deleted_paths" do
    it "returns deleted paths for v2" do
      deleted = DocsScanner.deleted_paths("v2")
      deleted.should_not be_empty
    end

    it "includes CLI paths in v2 deletions" do
      deleted = DocsScanner.deleted_paths("v2")
      deleted.includes?("cli/index.md").should be_true
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
  end

  describe "deletion inheritance behavior" do
    it "does not include deleted CLI pages in v2" do
      pages = DocsScanner.scan_version("v2")
      cli_pages = pages.select { |p| p.url_path.includes?("cli/") }
      cli_pages.should be_empty
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

    it "preserves non-deleted inherited pages in v2" do
      v2_pages = DocsScanner.scan_version("v2")
      # V2 should still have inherited pages that weren't deleted
      # For example, cookbook pages should still exist
      cookbook_pages = v2_pages.select { |p| p.url_path.includes?("cookbook/") }
      cookbook_pages.should_not be_empty
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

    it "returns nil for deleted pages in v2" do
      page = DocsScanner.find_page("v2", "cli")
      page.should be_nil
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

    it "v2 nav tree does not contain CLI section" do
      nav = DocsScanner.build_nav_tree_for_version("v2")
      cli_items = nav.select { |item| item.title.downcase.includes?("cli") }
      cli_items.should be_empty
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
