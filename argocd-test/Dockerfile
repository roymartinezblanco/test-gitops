FROM python:3.11-alpine

WORKDIR /app

# Copy and install dependencies
COPY pyproject.toml poetry.lock* ./
RUN pip install --no-cache-dir poetry && \
    poetry export -f requirements.txt -o requirements.txt --without-hashes && \
    pip install --no-cache-dir -r requirements.txt && \
    pip uninstall -y poetry

# Copy application files
COPY src/ ./src/
COPY config.yaml services-metadata.json ./

WORKDIR /workspace

ENTRYPOINT ["backstage-labeler"]
CMD ["--help"]

