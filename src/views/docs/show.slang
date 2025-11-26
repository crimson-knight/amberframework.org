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
          .d-flex.justify-content-between.align-items-start.mb-20
            nav.breadcrumbs aria-label="Breadcrumb"
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

            / Copy Page dropdown
            .copy-page-dropdown
              .dropdown
                button.btn.btn-sm.btn-outline-secondary.dropdown-toggle type="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"
                  i.fa.fa-copy.mr-1
                  | Copy Page
                .dropdown-menu.dropdown-menu-right
                  a.dropdown-item href="#" onclick="copyPageMarkdown(); return false;"
                    i.fa.fa-clipboard.mr-2
                    | Copy as Markdown
                  a.dropdown-item href="/docs/raw/#{@version_id}/#{@path}" target="_blank"
                    i.fa.fa-file-text-o.mr-2
                    | View as Markdown
                  .dropdown-divider
                  - claude_url = "https://claude.ai/new?q=#{URI.encode_www_form("Help me understand this documentation:\n\n" + page.content)}"
                  a.dropdown-item href="#{claude_url}" target="_blank" rel="noopener"
                    i.fa.fa-external-link.mr-2
                    | Open in Claude

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

  /* Copy page dropdown - Light mode (default) */
  .copy-page-dropdown .btn {
    background: #fff;
    border: 1.5px solid #f6a623;
    color: #f6a623;
    font-weight: 500;
    transition: all 0.2s ease;
    box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  }
  .copy-page-dropdown .btn:hover,
  .copy-page-dropdown .btn:focus {
    background: #f6a623;
    border-color: #f6a623;
    color: #fff;
    box-shadow: 0 2px 6px rgba(246,166,35,0.3);
  }
  .copy-page-dropdown .btn i { margin-right: 5px; }
  .copy-page-dropdown .dropdown-menu {
    min-width: 200px;
    border: 1px solid #e0e0e0;
    box-shadow: 0 4px 16px rgba(0,0,0,0.12);
    border-radius: 8px;
    padding: 6px 0;
    background: #fff;
  }
  .copy-page-dropdown .dropdown-item {
    font-size: 14px;
    padding: 10px 16px;
    color: #333;
    transition: all 0.15s ease;
  }
  .copy-page-dropdown .dropdown-item:hover {
    background: #fff5e6;
    color: #e69500;
  }
  .copy-page-dropdown .dropdown-item i {
    width: 18px;
    text-align: center;
    color: #f6a623;
    margin-right: 8px;
  }
  .copy-page-dropdown .dropdown-item:hover i { color: #e69500; }
  .copy-page-dropdown .dropdown-divider {
    margin: 6px 12px;
    border-top: 1px solid #eee;
  }

  /* Copy page dropdown - Dark mode */
  @media (prefers-color-scheme: dark) {
    .copy-page-dropdown .btn {
      background: #2d2d2d;
      border-color: #f6a623;
      color: #f6a623;
    }
    .copy-page-dropdown .btn:hover,
    .copy-page-dropdown .btn:focus {
      background: #f6a623;
      color: #1a1a1a;
    }
    .copy-page-dropdown .dropdown-menu {
      background: #2d2d2d;
      border-color: #444;
      box-shadow: 0 4px 20px rgba(0,0,0,0.4);
    }
    .copy-page-dropdown .dropdown-item {
      color: #e0e0e0;
    }
    .copy-page-dropdown .dropdown-item:hover {
      background: #3d3d3d;
      color: #f6a623;
    }
    .copy-page-dropdown .dropdown-item i { color: #f6a623; }
    .copy-page-dropdown .dropdown-divider {
      border-top-color: #444;
    }
  }

  /* Copy toast notification */
  .copy-toast {
    position: fixed;
    bottom: 20px;
    right: 20px;
    background: #28a745;
    color: white;
    padding: 12px 20px;
    border-radius: 6px;
    font-size: 14px;
    z-index: 9999;
    opacity: 0;
    transform: translateY(10px);
    transition: opacity 0.3s, transform 0.3s;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  }
  .copy-toast.show {
    opacity: 1;
    transform: translateY(0);
  }
  .copy-toast i { margin-right: 8px; }

/ Hidden element to store raw markdown for copy
- raw_url = "/docs/raw/#{@version_id}/#{@path}"

javascript:
  var rawMarkdownUrl = '#{raw_url}';

  function copyPageMarkdown() {
    fetch(rawMarkdownUrl)
      .then(response => response.text())
      .then(markdown => {
        navigator.clipboard.writeText(markdown).then(() => {
          showCopyToast('Copied to clipboard!');
        }).catch(err => {
          console.error('Failed to copy:', err);
          showCopyToast('Failed to copy', true);
        });
      })
      .catch(err => {
        console.error('Failed to fetch markdown:', err);
        showCopyToast('Failed to fetch page', true);
      });
  }

  function showCopyToast(message, isError) {
    var existing = document.querySelector('.copy-toast');
    if (existing) existing.remove();

    var toast = document.createElement('div');
    toast.className = 'copy-toast';
    toast.innerHTML = '<i class="fa fa-' + (isError ? 'times' : 'check') + '"></i>' + message;
    if (isError) toast.style.background = '#dc3545';
    document.body.appendChild(toast);

    setTimeout(function() { toast.classList.add('show'); }, 10);
    setTimeout(function() {
      toast.classList.remove('show');
      setTimeout(function() { toast.remove(); }, 300);
    }, 2000);
  }
