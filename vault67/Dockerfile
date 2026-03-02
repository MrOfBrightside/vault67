FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    python3 \
    git \
    curl \
    jq \
    tmux \
    tree \
    ca-certificates \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# vault67
COPY vault67/vault67 vault67/vault67-watch vault67/
COPY vault67/lib/ vault67/lib/
COPY vault67/agents/ vault67/agents/
COPY vault67/.vault67.conf.example vault67/

# farm33
COPY farm33/farm33 farm33/farm33-watch farm33/forge farm33/
COPY farm33/lib/ farm33/lib/
COPY farm33/prompts/ farm33/prompts/
COPY farm33/.farm33.conf.example farm33/.forge.conf.example farm33/

RUN chmod +x vault67/vault67 vault67/vault67-watch \
    farm33/farm33 farm33/farm33-watch farm33/forge \
    && chmod +x vault67/agents/*.sh 2>/dev/null || true

ENV OLLAMA_URL=http://host.docker.internal:11434
