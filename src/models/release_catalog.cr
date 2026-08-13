class ReleaseRecord
  include JSON::Serializable

  property project : String
  property repository : String
  property tag_name : String
  property name : String
  property published_at : String
  property published_on : String
  property prerelease : Bool
  property url : String
  property body : String

  def initialize(
    @project,
    @repository,
    @tag_name,
    @name,
    @published_at,
    @published_on,
    @prerelease,
    @url,
    @body,
  )
  end
end

class ReleaseSnapshot
  include JSON::Serializable

  property schema_version : Int32
  property synced_at : String
  property releases : Array(ReleaseRecord)

  def initialize(@schema_version, @synced_at, @releases)
  end
end

module ReleaseCatalog
  extend self

  PATH = "config/github_releases.json"

  def load : ReleaseSnapshot
    ReleaseSnapshot.from_json(File.read(PATH))
  rescue ex : File::NotFoundError | JSON::ParseException
    ReleaseSnapshot.new(1, "Unavailable", [] of ReleaseRecord)
  end

  def for_project(snapshot : ReleaseSnapshot, project : String) : Array(ReleaseRecord)
    snapshot.releases.select { |release| release.project == project }
  end

  def find(snapshot : ReleaseSnapshot, repository : String, tag_name : String) : ReleaseRecord?
    snapshot.releases.find do |release|
      release.repository == repository && release.tag_name == tag_name
    end
  end
end
