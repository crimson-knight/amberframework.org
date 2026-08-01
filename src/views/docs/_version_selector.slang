/ Version selector dropdown for documentation
/ Shows current version with dropdown to switch versions

- if version = @version
  .version-selector.mb-20
    .dropdown
      button.btn.btn-sm.btn-outline-secondary.dropdown-toggle type="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"
        | Version: #{version.label}
        - unless version.stable?
          span class="badge #{version.status_class} ml-2" = version.status.capitalize
      .dropdown-menu
        - @all_versions.each do |v|
          - if v.id == @version_id
            a.dropdown-item.active href="/docs/#{v.id}"
              | #{v.label}
              - unless v.stable?
                span class="badge #{v.status_class} ml-2" = v.status.capitalize
          - else
            a.dropdown-item href="/docs/#{v.id}"
              | #{v.label}
              - unless v.stable?
                span class="badge #{v.status_class} ml-2" = v.status.capitalize
    - if version.preview?
      .alert.alert-warning.mt-10.py-2.px-3.fs-12
        i.fa.fa-exclamation-triangle.mr-1
        | This is preview documentation for an upcoming release.
    - elsif version.deprecated?
      .alert.alert-secondary.mt-10.py-2.px-3.fs-12
        i.fa.fa-archive.mr-1
        | This documentation is for an older version.
        a.ml-1 href="/docs/latest" View current version
