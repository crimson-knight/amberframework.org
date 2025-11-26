doctype html
html lang="en"
  head
    meta charset="utf-8"
    meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"
    meta name="description" content="#{@meta}"
    meta name="keywords" content="amber, documentation, crystal, framework, guides, api"
    title = @title
    link rel="canonical" href="https://amberframework.org/docs/latest"
    link href="/dist/main.bundle.css" rel="stylesheet"
    link rel="apple-touch-icon" href="/favicon.png"
    link rel="icon" href="/favicon.png"
    link rel="icon" type="image/x-icon" href="/favicon.ico"
    script async="" src="https://www.googletagmanager.com/gtag/js?id=G-RER390YYB5"
    == render_template "layouts/google_analytics.slang"
    style
      | .docs-wrapper { display: flex; min-height: calc(100vh - 140px); }
      | .docs-sidebar { width: 280px; min-width: 280px; padding: 30px 20px; border-right: 1px solid #eee; background: #fafafa; }
      | .docs-sidebar .nav-tree { list-style: none; padding: 0; margin: 0; }
      | .docs-sidebar .nav-tree li { margin: 0; }
      | .docs-sidebar .nav-tree a { display: block; padding: 8px 12px; color: #555; text-decoration: none; border-radius: 4px; font-size: 14px; }
      | .docs-sidebar .nav-tree a:hover { background: #f0f0f0; color: #333; }
      | .docs-sidebar .nav-tree a.active { background: #f6a623; color: white; font-weight: 500; }
      | .docs-sidebar .section-title { font-weight: 600; color: #333; margin-top: 20px; margin-bottom: 5px; font-size: 15px; }
      | .docs-sidebar .nav-children { padding-left: 15px; }
      | .docs-main { flex: 1; max-width: 900px; padding: 40px 50px; }
      | .docs-content { line-height: 1.7; }
      | .docs-content h1 { margin-bottom: 30px; color: #333; }
      | .docs-content h2 { margin-top: 40px; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 1px solid #eee; }
      | .docs-content h3 { margin-top: 30px; margin-bottom: 15px; }
      | .docs-content pre { background: #282c34; color: #abb2bf; padding: 20px; border-radius: 6px; overflow-x: auto; }
      | .docs-content code { background: #f5f5f5; padding: 2px 6px; border-radius: 3px; font-size: 90%; }
      | .docs-content pre code { background: none; padding: 0; }
      | .hint { padding: 16px 20px; margin: 20px 0; border-left: 4px solid; border-radius: 4px; }
      | .hint p { margin: 0; }
      | .hint-info { background: #e7f3ff; border-color: #0070f3; }
      | .hint-warning { background: #fff8e6; border-color: #f5a623; }
      | .hint-success { background: #e6ffed; border-color: #28a745; }
      | .hint-danger { background: #ffe6e6; border-color: #dc3545; }
      | .code-block-titled { margin: 20px 0; }
      | .code-block-titled .code-title { background: #1e2127; color: #9da5b4; padding: 8px 20px; font-size: 12px; border-radius: 6px 6px 0 0; font-family: monospace; }
      | .code-block-titled pre { margin-top: 0; border-radius: 0 0 6px 6px; }
      | .breadcrumbs { margin-bottom: 20px; font-size: 14px; color: #666; }
      | .breadcrumbs a { color: #f6a623; text-decoration: none; }
      | .breadcrumbs a:hover { text-decoration: underline; }
      | .breadcrumbs .separator { margin: 0 8px; color: #ccc; }
      | .prev-next-nav { display: flex; justify-content: space-between; margin-top: 50px; padding-top: 30px; border-top: 1px solid #eee; }
      | .prev-next-nav a { display: block; padding: 15px 20px; background: #f9f9f9; border-radius: 6px; text-decoration: none; max-width: 45%; }
      | .prev-next-nav a:hover { background: #f0f0f0; }
      | .prev-next-nav .direction { display: block; font-size: 12px; color: #999; margin-bottom: 5px; }
      | .prev-next-nav .title { color: #333; font-weight: 500; }
      | .prev-next-nav .spacer { flex: 1; }
      | .page-ref { margin: 20px 0; padding: 15px; background: #f9f9f9; border-radius: 6px; }
      | .page-ref a { color: #f6a623; font-weight: 500; }
      | @media (max-width: 991px) { .docs-sidebar { display: none; } .docs-main { padding: 30px 20px; } }

  body.docs-page
    == render_template "layouts/_nav.slang"
    .docs-wrapper
      aside.docs-sidebar
        == render_template "docs/_sidebar.slang"
      main.docs-main
        == content
    == render_template "layouts/_footer.slang"

    script src="/assets/js/core.min.js"
    script src="/dist/main.bundle.js"
