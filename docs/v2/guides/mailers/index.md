---
title: "Mailers"
section: "guides"
order: 120
is_section: true
description: "Generate and deliver email with Amber V2's first-party mailer API"
---

# Mailers

Amber V2 includes `Amber::Mailer::Base`, MIME generation, attachments, an
in-memory delivery adapter, and SMTP delivery. Generate an ECR-backed mailer
with the standalone CLI:

```bash
amber generate mailer Digest --actions=weekly
```

The generator writes `src/mailers/digest_mailer.cr`, an ECR template under
`src/views/digest_mailer/`, and a mailer spec. The generated class implements
the required HTML and text bodies:

```crystal
class DigestMailer < Amber::Mailer::Base
  def initialize(@user_name : String, @user_email : String)
  end

  def html_body : String?
    ECR.render("src/views/digest_mailer/weekly.ecr")
  end

  def text_body : String?
    "Hello, #{@user_name}!"
  end
end
```

Escape user-provided values in HTML mail templates:

```crystal
<h1>Hello, <%= HTML.escape(@user_name) %>!</h1>
```

## Delivery configuration

The memory adapter is the default and is appropriate for tests. Configure SMTP
at application startup before delivering production mail:

```crystal
Amber::Mailer::Configuration.configure do |config|
  config.adapter = :smtp
  config.smtp_host = ENV["SMTP_HOST"]
  config.smtp_port = ENV.fetch("SMTP_PORT", "587").to_i
  config.smtp_username = ENV["SMTP_USERNAME"]?
  config.smtp_password = ENV["SMTP_PASSWORD"]?
  config.use_tls = true
  config.default_from = ENV.fetch("MAIL_FROM", "noreply@example.com")
  config.helo_domain = ENV.fetch("SMTP_HELO_DOMAIN", "localhost")
end
```

Do not commit SMTP credentials.

## Build and deliver

```crystal
result = DigestMailer.new("Alice", "alice@example.com")
  .to("alice@example.com")
  .subject("Your weekly digest")
  .deliver

raise result.error.to_s unless result.is_successful
```

Use `.from`, `.cc`, `.bcc`, `.reply_to`, `.header`, `.attach`, or
`.attach_file` before `.deliver` when the message needs them. The Quartz-Mailer
and Slang examples on the V1 page do not describe Amber V2's mailer API.
