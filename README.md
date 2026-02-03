---
title: "From Code to Content: Automating Your Blogger Workflow with GitHub"
author: "[Frank Jung](https://www.linkedin.com/in/frankjung/)"
date: 2026-02-03
---

![](images/banner.png)

For the modern developer, the desire to share technical insights is often
hindered by the "toil" of the publishing process. We live in our code editors
and terminal sessions, yet sharing those insights on platforms like
[Blogger](https://www.blogger.com/) traditionally requires a regression to
manual labour: copy-pasting HTML, wrestling with web-based WYSIWYG editors, and
manually managing assets. This discourages regular contribution, often resulting
in stale repositories and abandoned drafts.

By adopting a "Blogging as Code" approach, you can replace manual copy-pasting
with automated CI/CD pipeline management. By leveraging the
[Blogger REST API v3](https://developers.google.com/blogger/docs/3.0/reference/posts)
and [GitHub Actions](https://github.com/features/actions), you can treat your
blog with the same engineering rigour as your production software.

## 1. The API as Your Deployment Interface

The core shift in this methodology is viewing Blogger not as a website, but as a
deployment target. The Blogger REST API allows developers to bypass the browser
entirely, enabling programmatic creation and updates of posts.

Treating your blog as a deployment target via an API offers three critical
advantages for the DevOps-minded writer:

* Version Control: Your content resides in a Git repository, providing a single
  source of truth and a complete audit trail of changes.
* Consistency: Automation ensures that metadata, labels, and formatting are
  applied uniformly, eliminating inconsistent posts.
* GitOps for Content: Merging a pull request to your `main` branch becomes the
  trigger for your live content updates.

## 2. Security Starts in the Google Cloud Console

Automation requires a bridge of trust between GitHub and Google. This is
established in the Google Cloud Console by enabling OAuth 2.0. Setting up OAuth
2.0 involves a one-time configuration investment that yields long-term
efficiency gains.

For a detailed guide on setting up OAuth 2.0 and generating your refresh token
see
[Google Blogger API Authentication Setup](https://github.com/frankhjung/blogspot-publishing/blob/main/docs/authentication_setup.md).

You must explicitly search for and enable the Blogger API within your project.

Once the API is active, you will generate two critical credentials:

1. `CLIENT_ID`
2. `CLIENT_SECRET`

These are not just identifiers; they are the foundation used to generate a
`REFRESH_TOKEN`. Because GitHub Actions run in a non-interactive environment,
this refresh token is the key to secure, long-term authentication, allowing the
workflow to request fresh access tokens without manual intervention or the
storage of your primary account password.

## 3. Knowing Your Unique Identifiers

To route your content correctly, the pipeline must identify your specific
destination. This is handled by your `BLOG_ID`. Together, these parameters form
the mandatory authentication and identification components required for your
pipeline.

| Parameter | Description |
| --------- | ----------- |
| `CLIENT_ID` | The Google OAuth Client ID derived from the Cloud Console. |
| `CLIENT_SECRET` | The Google OAuth Client Secret used for authorization. |
| `REFRESH_TOKEN` | The secure token that allows for long-term, non-interactive API access. |
| `BLOG_ID` | The unique identifier for your specific destination blog. |

**[!WARNING]** Security best practice: It is essential that these four values
are stored as GitHub Secrets. Hardcoding these credentials in your YAML or
repository exposes your Google account to the public. By using GitHub Secrets,
they are encrypted and injected into the runner environment only during
execution.

## 4. The Anatomy of an Automated Post

The heavy lifting of the API interaction is managed by the
`frankhjung/blogspot-publishing@v1` GitHub Action. This utility expects a
specific set of inputs to govern how your content is delivered:

* `title`: The headline of your post.
* `source-file`: The path to the rendered HTML content.
* `blog-id`: Your destination identifier.
* `labels`: A comma-separated list of tags (e.g., "tech, devops, tutorial") to
  organise your content.
* `client-id` / `client-secret` / `refresh-token`: Your secure authentication
  suite.

The source-file input expects HTML. While the Blogger API consumes HTML, your
source remains in the format you prefer—such as Markdown or R Markdown. This is
handled by a "build" stage in your workflow that converts your source code into
the final deployment artifact.

## 5. Updates Without the Duplication Headache

A key feature of this automated approach is idempotency. In a traditional manual
workflow, fixing a typo means hunting through a dashboard. In an automated
system without idempotency, re-running a pipeline would simply create a
duplicate post.

The blogspot-publishing utility avoids this by using the post title as a unique
identifier. If a post with the same title already exists, it updates the
existing post (content only) instead of creating a duplicate. Include the title
as an environment variable in your GitHub pipeline. If you change the title,
then a new post will be created.

This supports a truly iterative writing process: push to `main`, and the Action
will find the existing post and update its content.

**Note:**

Because the title is the identifier, changing the title in your source file will
result in a new post being created. Additionally, to provide a final safety
check, all new posts are created as drafts by default, giving one last
opportunity for a manual preview before going live.

## 6. Bringing It All Together in YAML

### A Concrete Example: R Markdown with Data Visualisations

To see this in practice, consider the article-base-rate repository. This uses
complex data visualisations. The content is written in R Markdown (.Rmd),
requiring R (version 4.0+) and a Makefile to render the final HTML.

The `.github/workflows/publish.yml` integrates the build and deployment stages
into a single, cohesive CI/CD pipeline:

```yaml
name: Publish to Blogger
on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up R
        uses: r-lib/actions/setup-r@v2

      - name: Install dependencies and render
        run: |
          Rscript -e 'install.packages(c("rmarkdown", "ggplot2", "knitr"))'
          make base-rate.html

      - name: Publish to Blogger
        uses: frankhjung/blogspot-publishing@v1
        with:
          title: "Base Rate Fallacy Explained"
          source-file: "public/index.html"
          blog-id: ${{ secrets.BLOGGER_BLOG_ID }}
          client-id: ${{ secrets.BLOGGER_CLIENT_ID }}
          client-secret: ${{ secrets.BLOGGER_CLIENT_SECRET }}
          refresh-token: ${{ secrets.BLOGGER_REFRESH_TOKEN }}
          labels: "statistics, r-programming, data-science"
```

This configuration mirrors the logic of deploying to GitHub Pages but redirects
the final, styled output to the Blogger platform, bridging the gap between
sophisticated data analysis and public outreach.

## 7. Handling Format Constraints

The Blogger API expects post content as HTML, even if you prefer writing in
Markdown (as you would for a wiki or documentation site). The compromise is a
simple build step that converts your source into a single HTML file.

In practice, that usually looks like one of these:

* Markdown → HTML via Pandoc.
* R Markdown → HTML via `rmarkdown`.

The output HTML becomes the workflow artefact you pass as `source-file` (for
example, `public/index.html`).

## Conclusion: The Future of Your Technical Blog

Treating Blogger as a deployment target lets you apply the same engineering
discipline to writing that you already apply to software: version-controlled
content, repeatable builds, and automated publishing.

Once the pipeline is in place, publishing becomes routine: write in the format
you like, render to HTML, and let GitHub Actions update the existing post via
the API.

## More Information

* [Blogger REST API v3](https://developers.google.com/blogger/docs/3.0/reference/posts)
* [Git](https://git-scm.com/)
* [GitHub Actions](https://github.com/features/actions)
* [GitHub](https://github.com/)
* [Markdown guide](https://www.markdownguide.org/)
* [Pandoc](https://pandoc.org/)
* Example repository:
  [article-base-rate](https://github.com/frankhjung/article-base-rate)
* Example repository:
  [article-publish-to-blogspot](https://github.com/frankhjung/article-publish-to-blogspot).
  This post uses this repository as its source.
* GitHub Publish to Blogger Action:
  [GitHub Actions for Blogger](https://github.com/frankhjung/blogspot-publishing).
  Used to publish posts to Blogger.
* [R Markdown](https://rmarkdown.rstudio.com/)