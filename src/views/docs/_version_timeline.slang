/ Version Timeline Bar - shows document availability across versions
/ Only render if there are multiple versions and timeline data exists

- if @show_version_timeline && @version_timeline.size > 1
  .version-timeline.mb-20 aria-label="Document version history"
    .version-timeline-track
      - @version_timeline.each do |vt|
        - status_class = version_timeline_status_class(vt)
        - current_class = vt[:is_current] ? "current" : ""
        .version-timeline-segment class="#{status_class} #{current_class}" data-tooltip="#{version_timeline_tooltip(vt)}"
          - if vt[:exists]
            a.segment-link href="/docs/#{vt[:version_id]}/#{@path}"
              .segment-bar
                - if vt[:change_type] == "added"
                  .change-indicator.added
                - elsif vt[:change_type] == "reduced"
                  .change-indicator.reduced
              .segment-label = vt[:short_label]
          - else
            .segment-bar.unavailable
            .segment-label.unavailable = vt[:short_label]
