module Publication
  # Serves reviewed static publication artifacts through canonical site routes.
  class ServePublicPageController < ApplicationController
    # Serves the pioneer invitation and its machine-readable representations.
    def pioneers : String
      respond_with do
        html { serve_publication_page("pioneers", "html") }
        json { serve_publication_page("pioneers", "json") }
        markdown { serve_publication_page("pioneers", "md") }
      end
    end

    # Serves the V2 roadmap and its publication records.
    def roadmap : String
      respond_with do
        html { serve_publication_page("roadmap", "html") }
        json { serve_publication_page("roadmap", "json") }
        markdown { serve_publication_page("roadmap", "md") }
      end
    end

    # Serves the scoped research and retained measurement resources.
    def research : String
      respond_with do
        html { serve_publication_page("research", "html") }
        json { serve_publication_page("research", "json") }
        markdown { serve_publication_page("research", "md") }
      end
    end

    # Serves the last complete ecosystem release projection.
    def release_tracker : String
      respond_with do
        html { serve_publication_page("release-tracker", "html") }
        json { serve_publication_page("release-tracker", "json") }
        markdown { serve_publication_page("release-tracker", "md") }
      end
    end

    private def serve_publication_page(publication_folder : String, extension : String) : String
      # A fixed folder keeps request parameters outside the filesystem boundary.
      File.read("public/#{publication_folder}/index.#{extension}")
    end
  end
end
