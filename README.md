# Experimental reproducibility and integration

All data and code are publicly available on GitHub (https://github.com/zyxwars/bp)

## Prerequisites

### Docker

To ensure smooth and reproducible setup we provide docker containers with pre-configured settings. To run the code install a docker version compatible with 28.4.0
(https://www.docker.com/)

### OpenRouter

To connect to LLM providers an API key for OpenRouter (https://openrouter.ai/) is required. We utilize OpenRouter due to their wide selection of models including free and paid providers through a unified API. The platform also provides built-in cost monitoring and allows connecting to LLM observability and tracing platforms such as LangFuse (https://langfuse.com/).

## Run the full game

The provided docker compose file builds the client artifacts and serves them using nginx. The nginx server also proxies requests to the backend. Use this option for an end-to-end game deployment.

The command requires an `OPENROUTER_API_KEY` environment variable and docker volumes to persist simulation logs and read configuration from.

```
OPENROUTER_API_KEY=your-api-key docker compose up
```

After starting, the game will be accessible from your browser at http://localhost:8000

## Run a simulation

This command uses `gameConfig.ts` to pin the exact model selection and game configuration used in the simulations. The `gameConfig.ts` provided in `./data/simulation/` contains the settings from the paper.

The command requires an `OPENROUTER_API_KEY` environment variable and a docker volume to persist simulation logs and read configuration from.

```
docker build -t backend:latest ./backend
docker run \
  -e OPENROUTER_API_KEY=your-api-key \
  -v "./data:/app/data" \
  -v "./data/simulation/gameConfig.ts:/app/src/config/gameConfig.ts:ro" \
  backend:latest \
  pnpm start:simulate
```

## Logging

Game event logs are written to the mounted `data` directory in a newline-delimited JSON format (one self-contained event record per line), which can be replayed or analysed independently. The LLM-as-Judge script (`./backend/src/cli/judge.ts`) reads these logs and produces per-agent evaluation scores for initiative, honesty, and land captured.

## Human evaluation

The human evaluation study used the full game client-server setup deployed on public infrastructure. To replicate a similar study setup, enable the forms in `./frontend/config.cfg` and supply the pre-game and post-game Google Form URLs. The game automatically pre-fills the `user_id` field so responses can be matched to session logs.

Session logs produced during the study are archived alongside the simulation logs in the `./data/` directory. The anonymised raw responses from the Google Forms are also included in `./data/survey_raw.csv` so that the qualitative scoring can be independently verified.

## Data analysis

We provide the LLM-as-Judge script `./backend/src/cli/judge.ts` and jupyter notebooks used for visualization in `./data/` (`gameplay.ipynb`, `labels.ipynb`, `survey.ipynb`).

## Advanced setup

### Backend

#### Install

- Install a Node.js version compatible with the one specified in `./backend/.nvmrc` (https://nodejs.org/en/download)
- Install pnpm in a version compatible with the one specified in `./backend/package.json` (https://pnpm.io/)

#### Configuration

- `./backend/src/config/config.ts` — server and runtime settings
- `./backend/src/config/gameConfig.ts` — model selection and game rules (keep in sync with frontend constants)

#### Run

```
pnpm start:server
pnpm start:simulate

# Dev scripts automatically load .env if present in ./backend/.env
pnpm dev:server
pnpm dev:simulate
```

### Frontend

#### Install Godot

- Install a compatible Godot version (https://godotengine.org/download/archive/4.6.1-stable/)

#### Run from editor (debug)

- Open the project in Godot
- Press `Shift+F5` or select `Remote Deploy/Run in Browser` in the top right menu
- This starts a local debug build at http://localhost:8060/tmp_js_export.html

#### Run from CLI (release)

Build the project (make sure `godot` is on your PATH, or use an absolute path):

```
mkdir -p build && godot --headless --export-release "Web"
```

Serve the build output:

```
python3 -m http.server -d ./build
```

Navigate to http://localhost:8000

For public internet exposure, replace the Python dev server with a production-grade solution. See https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_web.html for more details.

### Configuration

Edit `./frontend/config.cfg` to point the frontend at your backend and optionally enable surveys:

```
[network]
; Backend url for llm services and logging
backend_url="http://localhost:8000/backend"

[forms]
; Whether to show surveys at the start and end of the game
forms_enabled=false
; NOTE: user_id will be pre-filled
; ex. https://docs.google.com/forms/d/e/MY_FORM_URL/viewform?usp=pp_url&entry.1234=
; entry will be pre-filled as entry.1234=user_id
pregame_form=""
postgame_form=""
```

Game rule constants in `./frontend/core/state/state.gd` must be kept in sync with the backend prompts:

```
# NOTE: KEEP IN SYNC WITH BACKEND PROMPTS
const SHIP_COUNT = 5;
const STARTING_GOLD = 3;
const WIN_GOLD = 20;
const MAX_MEMORY_SIZE = 30
```

## Asset licensing

### Icons

- https://fonts.google.com/icons
- Apache License 2.0

### Buildings

- https://quaternius.com/packs/ultimatefantasyrts.html
- Creative Commons CC0 1.0 Universal License

### Sail Ship

- https://quaternius.com/packs/ships.html
- Creative Commons CC0 1.0 Universal License

### Island textures

- https://ambientcg.com/view?id=Rock030
- https://ambientcg.com/view?id=Moss002
- https://ambientcg.com/view?id=Ground054
- Creative Commons CC0 1.0 Universal License

### Smoke texture used in flame particles

- https://brackeysgames.itch.io/brackeys-vfx-bundle
- Creative Commons CC0 1.0 Universal License
