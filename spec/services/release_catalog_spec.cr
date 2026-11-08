require "../spec_helper"

describe ReleaseCatalog do
  it "publishes dated framework and CLI releases from the checked-in snapshot" do
    snapshot = ReleaseCatalog.load

    snapshot.releases.should_not be_empty
    # The hourly sync keeps only the newest releases, so look up a release the snapshot holds
    # and name the V2 and CLI lines, not a tag.
    newest_release = snapshot.releases.first
    ReleaseCatalog.find(snapshot, newest_release.repository, newest_release.tag_name).should_not be_nil
    snapshot.releases.any? { |release| release.repository == "amberframework/amber" && release.tag_name.starts_with?("v2.0.0-beta.") }.should be_true
    snapshot.releases.any? { |release| release.repository == "amberframework/amber_cli" && release.tag_name.starts_with?("v2.0.") }.should be_true

    snapshot.releases.each do |release|
      release.published_on.should_not be_empty
      release.url.should start_with("https://github.com/#{release.repository}/releases/")
    end
  end

  it "keeps 1.5 current while preserving the dated V2 and legacy choices" do
    DocVersionConfig.reload

    DocVersionConfig.default.id.should eq("v1.5")
    DocVersionConfig.find("v2").try(&.release_date).should eq("2026-11-01")
    DocVersionConfig.find("v1.5").try(&.release_date).should eq("2026-08-01")
    DocVersionConfig.find("v1.4.1").try(&.archived?).should be_true
    DocsScanner.find_page("v1.5", "guides/installation").try(&.content).to_s.should contain("git checkout v1.5.0")
    DocsScanner.find_page("v1.5", "getting-started").try(&.content).to_s.should contain("published August 1, 2026")
  end
end
