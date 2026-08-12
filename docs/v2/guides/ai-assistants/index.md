---
title: "Amber Docs Assistant"
section: "guides"
order: 95
is_section: true
description: "Create a documentation-grounded custom GPT and use Amber pages with ChatGPT, Claude, or Gemini"
---

# Amber Docs Assistant

Every V2 documentation page has a plain-Markdown source and one-click handoffs
for ChatGPT, Claude, and Gemini. For repeat use, you can also create a custom
GPT whose knowledge is the complete published Amber V2 documentation.

The assistant is a reading and teaching layer. The documentation remains the
source of truth, and platform support claims still come from the published beta
matrix and its linked CI evidence.

For tools that support remote MCP servers, use the live, read-only
[Amber documentation MCP server](mcp.md). It searches the published V2 source
without requiring a knowledge-file refresh.

## Download the knowledge file

**Reference download: save this generated Markdown file before opening the GPT
builder.**

<a href="/docs/v2/knowledge.md" download>Download the Amber V2 documentation knowledge bundle</a>

The bundle combines every page currently published under `/docs/v2`, including
inherited maintenance references, and gives each section its canonical page
URL. It is text-forward so the GPT can retrieve code and prose without
interpreting a visual layout.

Download a fresh copy after a documentation release. A custom GPT does not
automatically replace a knowledge file when this website changes.

The Custom GPT workflow below uses a knowledge upload because GPT knowledge and
remote MCP configuration are different product surfaces. Do not paste the MCP
endpoint into the Knowledge field.

## Create the custom GPT

Custom GPT creation happens in ChatGPT's web editor and depends on your plan
and workspace permissions. Open [Explore GPTs](https://chatgpt.com/gpts), choose
**Create**, and use the configuration view. OpenAI's current
[creating and editing GPTs guide](https://help.openai.com/en/articles/8554397-creating-a-gpt)
documents access, knowledge uploads, Preview testing, sharing, and version
history.

Use these public fields:

| Field | Recommended value |
|---|---|
| Name | Amber Framework Guide |
| Description | Build and understand Amber V2 applications with answers grounded in the published documentation. |
| Knowledge | Upload the downloaded `amber-v2-docs.md` file. |

Knowledge supplies source material; instructions define behavior. Keep those
responsibilities separate.

## Where the examples go

- Paste the **GPT instructions** block into the Custom GPT editor's
  **Instructions** field. It is assistant configuration, not an Amber project
  file.
- Add each line in **Conversation starters** as its own starter in the same GPT
  configuration screen.
- Upload `amber-v2-docs.md` under **Knowledge**. Do not place it in an Amber
  application's source tree.

**GPT instructions: paste this complete Markdown into the Instructions field.**

```markdown
# Role
You are the Amber Framework Guide for Amber V2 beta users.

# Source contract
- Ground Amber answers in the uploaded Amber V2 documentation.
- Cite the canonical Amber documentation page named in the relevant bundle section.
- Distinguish release-gated web core, supported output, and preview ecosystem material.
- Prefer V2-authored guidance when an inherited Amber 1.4.1 reference conflicts with V2.
- Never invent a command, generator flag, package version, platform guarantee, benchmark, or file path.

# Teaching contract
- For every code example, name the exact file to create or edit.
- For every command, name the directory where it runs.
- Explain whether a snippet is a complete file, a replacement block, or an addition inside existing code.
- Use Crystal, ECR, YAML, CSS, JavaScript, or terminal labels accurately.
- Prefer the dependency-free web template unless the user deliberately chooses a preview integration.

# Build workflow
When a user wants to learn Amber through an app:
1. Start with the Build a Pet Tracker guide.
2. Keep HTML in ECR views, representation choice in controllers, routes in config/routes.cr, styles in app/assets/stylesheets, and browser modules in app/assets/javascript.
3. End with crystal spec, a native crystal build, and the exact URL or curl request that proves the feature.

# Uncertainty
If the uploaded documentation does not establish an answer, say what is unknown and link the closest canonical page. Do not convert an assumption into beta support language.
```

## Add useful conversation starters

**GPT configuration: add these as separate Conversation starters.**

```text
Build the Pet Tracker with me, one verified file at a time.
Show me where HTML, JSON, CSS, and JavaScript belong in an Amber V2 app.
Check whether a generator or platform is release-gated before I depend on it.
Explain this Amber error and cite the guide that supports your answer.
```

## Test before sharing

Use the GPT editor's Preview with questions that require retrieval rather than
general Crystal knowledge:

1. Ask it to start the Pet Tracker. It should name the parent directory for
   `amber new pet_tracker` and then `src/models/pet.cr`.
2. Ask for both HTML and JSON from one action. It should use `respond_with` and
   name `src/controllers/pets_controller.cr`.
3. Ask whether persistence and native generation are in the clean web compile
   guarantee. It should say they are preview surfaces.
4. Ask where CSS and JavaScript go. It should keep them local under `public/`
   and preserve the generated import map.

If an answer omits a file location, weakens the beta boundary, or cannot cite a
canonical page, tighten the instructions before adding capabilities. Web search
is optional; it is not a replacement for the uploaded release documentation.

## Use one page with any assistant

The buttons above each documentation page create a prompt containing that
page's public raw-Markdown URL. Use them when one page is enough. Copy as
Markdown remains the reliable fallback when an assistant does not accept a
prefilled prompt or the site is running only on localhost.

The page-level source contract is:

**Reference URL pattern:**

```text
https://amberframework.org/docs/v2/PAGE_PATH.md
```

For example, the Pet Tracker source is
`https://amberframework.org/docs/v2/guides/pet-tracker.md`. Add `.json` instead
when the assistant or script needs title, description, version, canonical URL,
inheritance state, and Markdown content in one structured object.
