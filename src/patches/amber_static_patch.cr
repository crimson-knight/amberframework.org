# Monkey-patch to fix Amber::Pipe::Static compatibility with Crystal 1.18+
# The directory_listing method signature changed from String to Path in newer Crystal versions
#
# This patch overrides the call_next_with_file_path method to convert String arguments to Path
# when calling directory_listing.
#
# See: https://github.com/amberframework/amber/issues/XXX (if applicable)

module Amber
  module Pipe
    class Static < HTTP::StaticFileHandler
      private def call_next_with_file_path(context, request_path, file_path)
        config = static_config

        if Dir.exists?(file_path)
          if config.is_a?(Hash) && config["dir_listing"] == true
            context.response.content_type = "text/html"
            # Fix: Convert String to Path for Crystal 1.18+ compatibility
            directory_listing(context.response, Path.new(request_path), Path.new(file_path))
          else
            call_next(context)
          end
        elsif File.exists?(file_path)
          return if etag(context, file_path)
          serve_file(context, file_path)
        else
          call_next(context)
        end
      end
    end
  end
end
