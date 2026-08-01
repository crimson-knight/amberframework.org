/ Documentation sidebar with version selector and navigation tree

/ Version selector
== render_template "docs/_version_selector.slang"

/ Navigation tree
nav.sidebar-nav
  h5.section-title Documentation
  ul.nav-tree
    - @nav_tree.each do |item|
      li
        - full_path = "#{@version_id}/#{@path}"
        - is_active = item.path == full_path || full_path.starts_with?(item.path + "/")
        - if is_active
          a.active href="/docs/#{item.path}"
            = item.title
            - if badge = item.badge
              span class="badge #{item.badge_class} ml-1 fs-10" = badge
        - else
          a href="/docs/#{item.path}"
            = item.title
            - if badge = item.badge
              span class="badge #{item.badge_class} ml-1 fs-10" = badge
        - unless item.children.empty?
          ul.nav-children
            - item.children.each do |child|
              li
                - child_active = child.path == full_path || full_path.starts_with?(child.path + "/")
                - if child_active
                  a.active href="/docs/#{child.path}"
                    = child.title
                    - if badge = child.badge
                      span class="badge #{child.badge_class} ml-1 fs-10" = badge
                - else
                  a href="/docs/#{child.path}"
                    = child.title
                    - if badge = child.badge
                      span class="badge #{child.badge_class} ml-1 fs-10" = badge
                - unless child.children.empty?
                  ul.nav-children
                    - child.children.each do |grandchild|
                      li
                        - gc_active = grandchild.path == full_path
                        - if gc_active
                          a.active href="/docs/#{grandchild.path}"
                            = grandchild.title
                            - if badge = grandchild.badge
                              span class="badge #{grandchild.badge_class} ml-1 fs-10" = badge
                        - else
                          a href="/docs/#{grandchild.path}"
                            = grandchild.title
                            - if badge = grandchild.badge
                              span class="badge #{grandchild.badge_class} ml-1 fs-10" = badge
