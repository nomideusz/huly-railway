# Deploy and Host Huly on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/huly-platform?utm_medium=integration&utm_source=button&utm_campaign=huly-platform)

[Huly](https://huly.io/) is the open-source all-in-one workspace that replaces Linear, Slack and Notion: issue tracking with projects, milestones and sprints, team chat with channels, threads and direct messages, collaborative documents, a planner and calendar, an HR and recruiting module. This template runs Huly 0.7.426, the current [huly-selfhost](https://github.com/hcengineering/huly-selfhost) release, on Postgres, Elasticsearch and Redpanda, and stores files in a Railway bucket.

## About Hosting Huly

Upstream's self-host compose file has 14 containers. This template runs the same software as four services and a bucket.

- **Huly.** The web front plus the account, transactor, collaborator, workspace, full-text, rekoni and stats services, all from the official `hardcoreeng/*` images at tag `v0.7.426`. They run together in one container and talk over localhost. Caddy sits in front on the only public domain and routes `/_accounts`, `/_transactor`, `/_collaborator`, `/_rekoni` and `/_stats` exactly as upstream's nginx does. Huly has no data on disk, so this service has no volume.
- **Postgres 17** holds accounts, workspaces and every issue, message and document. Huly supports Postgres as well as CockroachDB, and Postgres idles in a fraction of CockroachDB's memory.
- **Elasticsearch 7.17** backs full-text search. It is private, has machine learning switched off, and uses a 512 MB heap.
- **Redpanda 24.3** is the Kafka-compatible event queue that Huly's services use to talk to each other, for example to tell the indexer about changes. It runs single-node in dev-container mode with a 400 MB memory cap.
- **A Railway bucket (`Files`)** holds attachments, images and document bodies. Huly's `rootBucket` mode keeps every workspace under its own prefix in one bucket, so the bucket's single credential is enough and you don't need a MinIO service.

Upstream's `hulykvs` container is left out because none of the services in this stack call it. LiveKit (voice and video), mail, the AI bot, print, Gmail, Telegram and GitHub integrations are optional upstream add-ons and are not included.

## Common Use Cases

- Replacing Linear or Jira with an issue tracker your team hosts itself
- One place for engineering chat, specs and tasks, with no Slack and Notion seats to pay for
- A private, self-hosted knowledge base and wiki with real-time co-editing
- Planning and time-blocking work with the built-in planner and team calendar

## Dependencies for Huly Hosting

- Postgres 17 (included, private network only)
- Elasticsearch 7.17 (included, private network only)
- Redpanda 24.3 (included, private network only)
- A Railway Storage Bucket (included)

### Deployment Dependencies

- [Huly self-host repository](https://github.com/hcengineering/huly-selfhost)
- [Huly platform on GitHub](https://github.com/hcengineering/platform)
- [Template source on GitHub](https://github.com/nomideusz/huly-railway)

### Implementation Details

**Sign up, then create a workspace.** Open the Huly service's Railway domain once the deploy is green, choose Sign up, then create your first workspace. Creating a workspace sets up its data and loads the starter content, which takes a minute or two the first time. Sign-up works without email: no mail service is configured, so accounts don't need confirming.

**Close registration.** Sign-up is open to anyone who can reach the URL. Once your team has joined, set `DISABLE_SIGNUP=true` on the Huly service. Invite links still work after that. To get Huly's instance admin console, list your email in `ADMIN_EMAILS`.

**Back up `SERVER_SECRET`.** Every Huly service uses it to sign tokens. Changing it logs everyone out.

**Custom domain.** Add the domain to the Huly service, then set `PUBLIC_URL` to `https://your-domain`. The browser uses it for the account API and the websocket connections.

**Upgrades.** All `hardcoreeng/*` images are pinned to the same tag in the template repo's Dockerfile. Upgrading means bumping that tag, following upstream's [MIGRATION.md](https://github.com/hcengineering/huly-selfhost/blob/main/MIGRATION.md). The workspace service migrates existing workspaces when it starts.

**Resources.** Huly is heavy. On Railway, with one active workspace, the Huly service sits at about 1.05 GB, Elasticsearch at about 1 GB, Redpanda at about 165 MB and Postgres at about 150 MB, for roughly 2.4 GB in total. Huly and Elasticsearch each go over the Trial plan's 1 GB per service, so use the Hobby plan or above.

## Why Deploy Huly on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Huly on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
