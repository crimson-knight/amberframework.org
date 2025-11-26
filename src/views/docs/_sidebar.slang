nav.sidebar-nav
  h5.section-title Documentation
  ul.nav-tree
    - @nav_tree.each do |item|
      li
        - is_active = item.path == @path || @path.starts_with?(item.path + "/")
        - if is_active
          a.active href="/docs/#{item.path}" = item.title
        - else
          a href="/docs/#{item.path}" = item.title
        - unless item.children.empty?
          ul.nav-children
            - item.children.each do |child|
              li
                - child_active = child.path == @path
                - if child_active
                  a.active href="/docs/#{child.path}" = child.title
                - else
                  a href="/docs/#{child.path}" = child.title
                - unless child.children.empty?
                  ul.nav-children
                    - child.children.each do |grandchild|
                      li
                        - gc_active = grandchild.path == @path
                        - if gc_active
                          a.active href="/docs/#{grandchild.path}" = grandchild.title
                        - else
                          a href="/docs/#{grandchild.path}" = grandchild.title
