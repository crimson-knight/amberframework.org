header.header.header-inverse.h-fullscreen.p-0.bg-primary.overflow-hidden.orange-header
  canvas.constellation
  .container.text-center
    .row.h-full.align-items-center
      .col-12.col-md-8.offset-md-2
        img.img-fluid.img-amber-logo src="/assets/img/amber-logo-t-bg.png" alt="amber logo"
        h1.d-none
          | Amber Framework
        br
        h2
          | Productivity. Performance. Happiness.
        p.lead.text-white.fs-20
          | Amber makes building web applications fast, simple, and enjoyable.
          br
          | Get started with blazing fast performance.
          br
          | Latest release: #{@latest_amber_version} - #{@latest_amber_release_date}
        br
        a.btn.btn-lg.btn-round.shadow-3.btn-primary href="https://docs.amberframework.org/amber/getting-started" target="_blank"
          | Getting Started Guide
        br
