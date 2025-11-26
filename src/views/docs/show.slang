- @title = "#{@page.not_nil!.title} - Documentation - Amber Framework"
- @meta = @page.not_nil!.description.empty? ? "Amber Framework documentation" : @page.not_nil!.description

- page = @page.not_nil!
- version = @version

header.header.header-inverse.overflow-hidden.orange-header style="padding: 60px 0 40px;"
  .container.text-center
    .row
      .col-12.col-lg-8.offset-lg-2
        h1.display-4.hidden-sm-down
          = page.title
          - if badge = @page_badge
            span class="badge #{@page_badge_class} ml-2 fs-14 align-middle" = badge
        h1.hidden-md-up
          = page.title
          - if badge = @page_badge
            span class="badge #{@page_badge_class} ml-2 fs-12" = badge
        p.fs-20.opacity-70
          | Amber Framework Documentation
          - if version
            span.mx-2 |
            span = version.label

main.main-content
  .section.py-30
    .container
      .row
        .col-12.col-lg-3
          nav.docs-sidebar.mb-30
            == render_template "docs/_sidebar.slang"
        .col-12.col-lg-9
          nav.breadcrumbs.mb-20 aria-label="Breadcrumb"
            a href="/docs" Docs
            - if version
              span.separator.mx-2 /
              a href="/docs/#{@version_id}" = version.label
            - @breadcrumbs.each do |crumb|
              span.separator.mx-2 /
              a href="/docs/#{crumb[:path]}" = crumb[:title]
            - unless @path.empty?
              span.separator.mx-2 /
              span = page.title

          article.docs-content
            == render_markdown(page.content)

          nav.prev-next-nav.mt-50.pt-30.border-top
            .row
              .col-6
                - if prev_page = @prev_page
                  a.d-block.p-15.bg-gray.rounded href="/docs/#{prev_page.url_path}"
                    small.text-muted Previous
                    br
                    span.fw-600 = prev_page.title
              .col-6.text-right
                - if next_page = @next_page
                  a.d-block.p-15.bg-gray.rounded href="/docs/#{next_page.url_path}"
                    small.text-muted Next
                    br
                    span.fw-600 = next_page.title

css:
  /* Version selector styles */
  .version-selector { margin-bottom: 15px; }
  .version-selector .dropdown-toggle { font-size: 13px; }
  .version-selector .dropdown-menu { font-size: 13px; }
  .version-selector .dropdown-item.active { background: #f6a623; color: #fff; }

  /* Badge styles */
  .badge-success { background-color: #28a745; color: #fff; }
  .badge-info { background-color: #17a2b8; color: #fff; }
  .badge-warning { background-color: #ffc107; color: #212529; }
  .badge-secondary { background-color: #6c757d; color: #fff; }
  .badge-dark { background-color: #343a40; color: #fff; }
  .badge { font-weight: 500; padding: 3px 8px; border-radius: 3px; }

  /* Sidebar styles */
  .docs-sidebar .nav-tree { list-style: none; padding: 0; margin: 0; }
  .docs-sidebar .nav-tree li { margin: 0; }
  .docs-sidebar .nav-tree a { display: block; padding: 6px 0; color: #555; text-decoration: none; font-size: 14px; }
  .docs-sidebar .nav-tree a:hover { color: #f6a623; }
  .docs-sidebar .nav-tree a.active { color: #f6a623; font-weight: 600; }
  .docs-sidebar .nav-children { padding-left: 15px; border-left: 1px solid #eee; margin-left: 5px; }

  /* Content styles */
  .docs-content { line-height: 1.8; }
  .docs-content h2 { margin-top: 40px; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 1px solid #eee; }
  .docs-content h3 { margin-top: 30px; margin-bottom: 15px; }
  .docs-content pre { background: #282c34; color: #abb2bf; padding: 20px; border-radius: 6px; overflow-x: auto; }
  .docs-content code { background: #f5f5f5; padding: 2px 6px; border-radius: 3px; font-size: 90%; }
  .docs-content pre code { background: none; padding: 0; }

  /* Hint boxes */
  .hint { padding: 16px 20px; margin: 20px 0; border-left: 4px solid; border-radius: 4px; }
  .hint p { margin: 0; }
  .hint-info { background: #e7f3ff; border-color: #0070f3; }
  .hint-warning { background: #fff8e6; border-color: #f5a623; }
  .hint-success { background: #e6ffed; border-color: #28a745; }
  .hint-danger { background: #ffe6e6; border-color: #dc3545; }

  /* Code blocks */
  .code-block-titled { margin: 20px 0; }
  .code-block-titled .code-title { background: #1e2127; color: #9da5b4; padding: 8px 20px; font-size: 12px; border-radius: 6px 6px 0 0; font-family: monospace; }
  .code-block-titled pre { margin-top: 0; border-radius: 0 0 6px 6px; }

  /* Page references and navigation */
  .page-ref { margin: 20px 0; padding: 15px; background: #f9f9f9; border-radius: 6px; }
  .page-ref a { color: #f6a623; font-weight: 500; }
  .breadcrumbs a { color: #f6a623; text-decoration: none; }
  .breadcrumbs a:hover { text-decoration: underline; }
  .orange-header { background: linear-gradient(135deg, #f6a623 0%, #f78b00 100%); }

  /* Alert styles for version warnings */
  .alert { border-radius: 4px; }
  .alert-warning { background: #fff8e6; border: 1px solid #ffc107; color: #856404; }
  .alert-secondary { background: #e9ecef; border: 1px solid #6c757d; color: #383d41; }
