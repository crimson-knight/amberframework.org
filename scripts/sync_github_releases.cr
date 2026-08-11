require "http/client"
require "json"
require "time"
require "../src/models/release_catalog"

REPOSITORIES = [
  {project: "Amber Framework", repository: "amberframework/amber", limit: 8},
  {project: "Amber CLI", repository: "amberframework/amber_cli", limit: 5},
]

headers = HTTP::Headers{
  "Accept"               => "application/vnd.github+json",
  "User-Agent"           => "amberframework.org-release-sync",
  "X-GitHub-Api-Version" => "2022-11-28",
}

if token = ENV["GITHUB_TOKEN"]?
  headers["Authorization"] = "Bearer #{token}"
end

releases = REPOSITORIES.flat_map do |source|
  url = "https://api.github.com/repos/#{source[:repository]}/releases?per_page=#{source[:limit]}"
  response = HTTP::Client.get(url, headers: headers)
  unless response.success?
    STDERR.puts "GitHub release sync failed for #{source[:repository]}: HTTP #{response.status_code}"
    exit 1
  end

  JSON.parse(response.body).as_a.compact_map do |entry|
    next if entry["draft"].as_bool

    tag_name = entry["tag_name"].as_s
    published_at = entry["published_at"]?.try(&.as_s?) || entry["created_at"].as_s
    published_on = Time.parse_rfc3339(published_at).to_s("%B %d, %Y").gsub(" 0", " ")

    ReleaseRecord.new(
      project: source[:project],
      repository: source[:repository],
      tag_name: tag_name,
      name: entry["name"]?.try(&.as_s?) || tag_name,
      published_at: published_at,
      published_on: published_on,
      prerelease: entry["prerelease"].as_bool,
      url: entry["html_url"].as_s,
      body: entry["body"]?.try(&.as_s?) || "",
    )
  end
end.sort_by(&.published_at).reverse

current = ReleaseCatalog.load
if current.releases.to_json == releases.to_json
  puts "GitHub release snapshot is already current."
  exit
end

snapshot = ReleaseSnapshot.new(
  schema_version: 1,
  synced_at: Time.utc.to_rfc3339,
  releases: releases,
)
File.write(ReleaseCatalog::PATH, snapshot.to_pretty_json + "\n")
puts "Updated #{ReleaseCatalog::PATH} with #{releases.size} published releases."
