require "asset_pipeline/static_assets"

compiler = AssetPipeline::StaticAssets::Compiler.new(
  source_root: "app/assets",
  output_root: "public/assets",
  public_path: "/assets"
)

manifest = ARGV.includes?("--check") ? compiler.check : compiler.build
verb = ARGV.includes?("--check") ? "Verified" : "Built"
puts "#{verb} #{manifest.assets.size} static assets"
