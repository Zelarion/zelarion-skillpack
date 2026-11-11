# VPS safety — shared production servers (non-negotiable)

The team's VPS hosts many unrelated production apps at once (PM2 processes, Docker containers,
databases, one Nginx). A careless command for one project takes the others down. These rules apply
to every command given to the user for a server and to every command run on one.

## Evidence before claims

- **Read the local server notes first.** Before writing any server command, read the infrastructure
  notes on this machine (the master server inventory, per-project deploy notes, deploy-state rules,
  and the second-brain vault notes kept current by `/vps-sync`). Note their dates; a note is a
  snapshot, not the live state.
- **Never claim a fact about the live server that has not been verified on it.** "Port 5080 is free",
  "Docker Compose is installed", "there is 2 GB of RAM to spare", "nothing else uses this domain" are
  all claims that need fresh read-only output from the server, not assumptions or old notes.
- **Gather context with a read-only pass first.** Give the user one copy-paste block of read-only
  commands, written as if they are already logged in on the server, and wait for the output before
  giving any command that changes something.

## What counts as read-only

Allowed in a context-gathering pass: `hostname`, `uptime`, `free -h`, `df -h`, `swapon --show`,
`ss -ltnp`, `ps`, `pm2 ls` / `pm2 jlist` (filtered — see below), `pm2 describe <name>` (filtered),
`docker ps`, `docker images`, `docker system df`, `nginx -t`, `nginx -T` (filtered), `ls`, `cat` of
non-secret files, `grep`, `getent hosts`, `curl` to a local health endpoint, `git status` / `git log`,
`certbot certificates`, `ufw status`.

Never in a read-only pass: `pm2 save`, `pm2 restart|reload|stop|delete|start|flush|update`,
`systemctl restart|reload|stop`, `nginx -s`, `docker run|stop|rm|pull|compose up|down`, package
installs, `git pull`, anything that writes a file.

## Never leak secrets while gathering

- Do not print `.env*` files, `pm2 env`, raw `pm2 jlist` / `pm2 describe` (they include every
  environment variable), `docker inspect` (includes container env), or `nginx -T` unfiltered if it
  may contain auth lines. Extract only the fields needed (name, id, status, restarts, memory, cwd,
  exec mode, PORT).

## Changing the server without collateral damage

- **Fingerprint before and after.** Capture `name|id|status|restarts|uptime` for every PM2 process
  and `name|status` for every container before the change; capture it again after. Every process
  that is not the target must be identical. Report the comparison.
- **Target by exact name, never by "all".** No `pm2 restart all`, `pm2 reload all`, `pm2 kill`,
  `docker compose down` in a shared folder, `docker system prune -a`, `killall node`. Confirm the exact
  PM2 name or id from fresh output first; a wrong name restarts another project.
- **Ports, domains and paths:** pick a port only after the read-only pass shows it free; give each
  app its own Nginx site file with a unique `server_name`; never edit another project's site file.
  Always run `nginx -t` and only `systemctl reload nginx` (never restart) after it passes.
- **Protect shared resources.** Heavy work (Docker image builds, `npm ci` of large trees, big
  migrations) can exhaust RAM and get other apps OOM-killed. Build images off the server and ship
  them, or verify free memory and add limits first. New containers get `mem_limit` and `cpus`.
- **Every change has a rollback** written next to it before it is run, plus a backup of anything it
  overwrites (env file, site file, app dir).
- **No destructive commands without an explicit, specific yes from the user** for that command:
  deleting files or directories, dropping or truncating databases, `pm2 delete`, removing images or
  volumes, firewall changes, certificate revocation.
