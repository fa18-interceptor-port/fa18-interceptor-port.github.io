# FA-18 Interceptor website

Static site for [fa18-interceptor-port](https://github.com/Grumbel/fa18-interceptor-port),
structured like [kurvenrausch.github.io](https://github.com/kurvenrausch/kurvenrausch.github.io):

- **Nix flake** pulls the playable **WASM** package and the downloadable
  ports (Windows 64/32-bit zips, the Android APK, the R36S PortMaster zip)
  from the game flake and assembles `index.html`, `play/` and `downloads/`
  into a single store path; building the site builds them all
- **GitHub Pages** deploys that path via `.github/workflows/pages.yml`
- **Local preview**: `nix run .#serve`

The original ADF is **not** redistributed. Visitors must supply their own
legal copy (documented on the page and in `downloads/README.txt`).

## Layout

```
.
├── flake.nix                 # site only (builds come from Grumbel/fa18-interceptor-port)
├── index.html                # landing page
├── images/                   # icon / screenshots
├── scripts/serve.sh          # local HTTP server (no-cache headers)
└── .github/workflows/pages.yml
```

## Commands

```bash
# Build the full site (HTML + WASM under play/ + downloads/)
nix build
ls result/
# result/index.html  result/images/  result/play/fa18.{html,js,wasm}
# result/downloads/fa18-win64.zip  fa18-win32.zip  fa18.apk
# result/downloads/r36s/fa18.zip

# Build against a local checkout of the game instead of GitHub:
nix build --override-input fa18 git+file://$HOME/projects/fa18-interceptor-port

# Serve and open a browser (port 8765 by default)
nix run .
# or:
FA18_PORT=9000 nix run .#serve
```

## GitHub Pages

1. Push this repository to GitHub (e.g. `Grumbel/fa18-interceptor.github.io`
   or under an org/user pages repo).
2. Under **Settings → Pages**, set the source to **GitHub Actions**.
3. On every push to `master`, the workflow runs `nix build` and deploys
   `result/` with `actions/deploy-pages`.

The WASM build and the ports are built by the
[fa18-interceptor-port](https://github.com/Grumbel/fa18-interceptor-port)
flake; this site only packages them. After pushing game changes, run
`nix flake update fa18` here and push to rebuild everything. The build
runs on **x86_64-linux** only (Android SDK).

## License

Site scaffolding: use freely (same spirit as the kurvenrausch site).
Game binary/WASM: **GPL-3.0-or-later** (see
[Grumbel/fa18-interceptor-port](https://github.com/Grumbel/fa18-interceptor-port)).
The original 1988 game remains under its original copyright and is not
included in any download.
