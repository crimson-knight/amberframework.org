require "../spec_helper"

describe ReleaseCatalog do
  it "publishes dated framework and CLI releases from the checked-in snapshot" do
    snapshot = ReleaseCatalog.load

    snapshot.releases.should_not be_empty
    ReleaseCatalog.find(snapshot, "amberframework/amber", "v1.5.0").should_not be_nil
    ReleaseCatalog.find(snapshot, "amberframework/amber", "v2.0.0-beta.2").should_not be_nil
    ReleaseCatalog.find(snapshot, "amberframework/amber_cli", "v2.0.3").should_not be_nil

    snapshot.releases.each do |release|
      release.published_on.should_not be_empty
      release.url.should start_with("https://github.com/amberframework/")
    end
  end

  it "keeps 1.5 current while preserving the dated V2 and legacy choices" do
    DocVersionConfig.reload

    DocVersionConfig.default.id.should eq("v1.5")
    DocVersionConfig.find("v2").try(&.release_date).should eq("2026-07-31")
    DocVersionConfig.find("v1.5").try(&.release_date).should eq("2026-08-01")
    DocVersionConfig.find("v1.4.1").try(&.archived?).should be_true
    DocsScanner.find_page("v1.5", "guides/installation").try(&.content).to_s.should contain("git checkout v1.5.0")
    DocsScanner.find_page("v1.5", "getting-started").try(&.content).to_s.should contain("published August 1, 2026")
  end
end
