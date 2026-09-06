# Three-Tier Task Manager — DevOps Portfolio Project

A minimal Task Manager app used as the application layer for a full AWS DevOps
pipeline: **React (frontend) → Node/Express (backend API) → MySQL (database)**.

This repo is Phase 1 of the project (the application code). Docker, Terraform,
and CI/CD come in later phases.

## Structure

```
devops-three-tier-app/
├── backend/
│   ├── Dockerfile
│   ├── .dockerignore
│   └── src/            # Express REST API (tasks CRUD), talks to MySQL
├── frontend/
│   ├── Dockerfile               # multi-stage: build React, serve via nginx
│   ├── nginx.conf.template       # envsubst-rendered nginx config
│   ├── .dockerignore
│   └── src/            # React single-page app
├── database/           # SQL schema/seed script
├── docker-compose.yml  # local 3-tier stack, mirrors AWS layout
└── docs/                # architecture notes (added in later phases)
```

## Running with Docker (recommended - mirrors AWS)

This is the setup that most closely matches how the app runs in ECS Fargate:
frontend nginx container + backend node container, each built from their own
Dockerfile, talking to a MySQL container.

```bash
docker-compose up --build
```

- Frontend: http://localhost:3000 (this is what the ALB will expose in AWS)
- Backend directly: http://localhost:4000/health (exposed here for debugging;
  in AWS the backend target group is only reachable from the ALB, not the internet)
- MySQL: not exposed to the host by default (matches RDS being private-subnet-only)

Tear down (keeps data):
```bash
docker-compose down
```

Tear down and wipe the database volume:
```bash
docker-compose down -v
```

### How the `/api` routing works in both environments

The React app always calls a **relative** `/api/tasks` path — it never hardcodes
a host. Two different mechanisms make that work depending on environment:

| Environment | Who handles `/api/*` routing |
|---|---|
| `docker-compose` | The frontend's nginx container proxies `/api/*` to the `backend` container over the docker network (see `frontend/nginx.conf.template`) |
| AWS (Phase 3+) | The Application Load Balancer routes `/api/*` requests directly to the backend ECS target group, bypassing the frontend container entirely |

Same frontend build artifact, zero code changes, two different infrastructures
doing the routing. This is intentional and worth calling out on your resume/in
interviews as a deliberate infra-driven design decision.

## Running locally (before Docker)

**1. Start MySQL** (adjust to however you run MySQL locally, e.g. Homebrew, apt, or a container):
```bash
mysql -u root -p < database/init.sql
```
Or create a user matching `backend/.env.example` and let the app create the table itself
(`backend/src/db.js` runs `CREATE TABLE IF NOT EXISTS` on startup).

**2. Start the backend**
```bash
cd backend
cp .env.example .env   # edit DB_* values to match your local MySQL
npm install
npm run dev             # nodemon, or `npm start` for plain node
```
Backend runs on http://localhost:4000. Health check: http://localhost:4000/health

**3. Start the frontend**

The frontend calls a relative `/api/tasks` path (by design — see comment in
`frontend/src/App.js`), so for local dev without nginx you need to proxy API
calls to the backend. Add this to `frontend/package.json`:
```json
"proxy": "http://localhost:4000"
```
Then:
```bash
cd frontend
npm install
npm start
```
Frontend runs on http://localhost:3000 and proxies `/api/*` to the backend.

## API endpoints

| Method | Path             | Description       |
|--------|------------------|--------------------|
| GET    | /api/tasks       | List all tasks     |
| GET    | /api/tasks/:id   | Get one task       |
| POST   | /api/tasks       | Create a task       |
| PUT    | /api/tasks/:id   | Update a task       |
| DELETE | /api/tasks/:id   | Delete a task       |
| GET    | /health          | Health check (used by ALB/ECS) |

## Why a relative `/api` path?

In AWS, an Application Load Balancer will route `/api/*` requests to the
backend ECS target group and everything else to the frontend target group
(path-based routing). Using a relative path in the React app means the exact
same production build works with zero rebuilds or environment-specific
config — a deliberate DevOps-friendly choice, not an accident.

## Next phases

- ~~**Phase 2**: Dockerfiles for frontend/backend + docker-compose for local parity with prod~~ ✅
- **Phase 3**: Terraform for VPC, RDS, ECR, ALB, ECS Fargate
- **Phase 4**: CodePipeline + CodeBuild CI/CD
- **Phase 5**: Deploy + HTTPS via ACM
- **Phase 6**: CloudWatch monitoring, autoscaling, resume write-up
