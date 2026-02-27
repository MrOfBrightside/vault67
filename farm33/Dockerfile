FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    python3 \
    git \
    curl \
    tmux \
    tree \
    ca-certificates \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY farm33 farm33-watch forge ./
COPY prompts/ prompts/
COPY .farm33.conf.example .forge.conf.example .

RUN chmod +x farm33 farm33-watch forge

ENV OLLAMA_URL=http://host.docker.internal:11434

ENTRYPOINT ["./farm33"]
CMD ["watch"]
