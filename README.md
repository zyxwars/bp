# Technical Documentation

## Setup

Docker version compatible with 28.4.0 is required to run the containerized frontend and backend.

To connect to model providers an API key for OpenRouter is required (https://openrouter.ai/). The project requires setting the `OPENROUTER_API_KEY` environment variable.

(Optional) If you also want to run the jupyter notebooks for visualization install Python version compatible with 3.12.3.

## Installation Manual

1. Clone the project from GitHub (https://github.com/zyxwars/bp) OR unzip ZIP file
2. (Optional) Install visualization dependencies `pip install -r data/requirements.txt`

## User's Manual

### Run the Full Game - Main option

![Game open in a browser window on localhost port 8000](assets/images/game-browser.png)

The provided docker compose file builds the client artifacts and serves them using nginx. The nginx server also proxies requests to the backend. Use this option for an end-to-end game deployment.

1. Start containers `OPENROUTER_API_KEY=your-api-key docker compose up`
2. Open http://localhost:8000 in your browser.
3. Wait for the game to load and click `Start Game`.

### Run a Simulation (No gui/human player)

This command uses `gameConfig.ts` provided in `./data/simulation/` to pin the exact model selection and game configuration used we used when testing agent-only games.

1. Build only backend image and run simulation:

```
docker build -t backend:latest ./backend
docker run \
 -e OPENROUTER_API_KEY=your-api-key \
 -v "./data:/app/data" \
 -v "./data/simulation/gameConfig.ts:\
 /app/src/config/gameConfig.ts:ro" \
 backend:latest pnpm start:simulate
```

### Data collection

#### Sessions logs

Session data is recorded automatically under `./data/userId-sessionId.jsonl` in your current working directory after you start a game sessions.

#### External survey intergration

If you wish to replicate or extend our study you can provide google forms urls in the game.

1. In `./frontend/config.cfg`, set `forms_enabled=true` and provide the pre-game and post-game Google Form URLs.
2. Run the full game from Section~\ref{subsec:Run-Full-Game}.

### Data Analysis

#### Labeling

1. Run the judge script using the same command used in
   Section~\ref{subsec:Run-Simulation}, replacing
   `pnpm start:simulate` with `pnpm start:judge <path-to-session-to-judge>`.
2. After finishing the script should output `<path-to-session-to-judge>-labels.jsonl`

#### Visualization

1. Open the notebooks in `./data/{gameplay.ipynb, labels.ipynb, survey.ipynb}` with standard Jupyter tools.

## Developer Manual

### Backend

**Install**

1. Install a Node.js version compatible with
   `./backend/.nvmrc`.
2. Install Pnpm in a version compatible with
   `./backend/package.json` and install dependencies using `pnpm install`.

**Configuration**

1. `./backend/src/config/config.ts` --- server and
   runtime settings.
2. `./backend/src/config/gameConfig.ts` --- model
   selection and game rules (keep in sync with frontend constants).

**Run**

```
pnpm start:server
pnpm start:simulate

# Dev scripts automatically load .env if present in ./backend/.env

pnpm dev:server
pnpm dev:simulate
```

### Frontend

**Install Godot**

1. Install Godot (https://godotengine.org/download/archive/4.6.1-stable/).

**Run from Editor (Debug)**

1. Open the project in Godot.
2. Press `Shift+F5` or select `Remote Deploy/Run in Browser` in the top right menu.
3. Open http://localhost:8060/tmp_js_export.html in your browser.

**Run from CLI (Release)**

1. Build the project (`godot` must be on your PATH):

```
mkdir -p build && godot --headless --export-release "Web"
```

2. Serve the build output:

```
python3 -m http.server -d ./build
```

3. Open http://localhost:8000 in your browser.

#### Configuration

1. Edit `./frontend/config.cfg` to point the frontend
   at your backend and optionally enable surveys:

```
[network]
; Backend url for llm services and logging
backend_url="http://localhost:8000/backend"
; Use backend_url="http://localhost:3000" if not running docker compose

[forms]
; Whether to show surveys at the start and end of the game
forms_enabled=false
; NOTE: user_id will be pre-filled
; ex. https://docs.google.com/forms/d/e/MY_FORM_URL/
; viewform?usp=pp_url&entry.1234=
; entry will be pre-filled as entry.1234=user_id
pregame_form=""
postgame_form=""
```

2. Keep game rule constants in
   `./frontend/core/state/state.gd` in sync with the
   backend prompts:

```

# NOTE: KEEP IN SYNC WITH BACKEND PROMPTS

const SHIP_COUNT = 5;
const STARTING_GOLD = 3;
const WIN_GOLD = 20;
const MAX_MEMORY_SIZE = 30
```
