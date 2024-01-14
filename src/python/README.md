# Python

## Requirements
+ Python 3.11
+ AWS Access

## Installation
```bash
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

## Usage
Export ENV Vars for defining S3 Parameters.

```bash
export BUCKET=<bucket-name>
export PREFIX=<prefix>
export OUTPUT_PREFIX=<output-prefix>
```

Run the script
```bash
python script.py
```

## BUILD DOCKER IMAGE
 Build for local architecture.
```bash
docker build -t aws-batch-single . 
```

Build for ARM architecture.
```bash
docker buildx build --platform linux/arm64 -t aws-batch-single-arm --load .
```

Buil for AMD64 architecture.
```bash
docker buildx build --platform linux/amd64 -t aws-batch-single-amd64 --load .
```

## RUN DOCKER IMAGE
Run Docker Image locally
```bash
docker run --rm  -e BUCKET=<bucket-name> -e PREFIX=<prefix> -e OUTPUT_PREFIX=<output-prefix> -e AWS_ACCESS_KEY_ID=<access-key> -e AWS_SECRET_ACCESS_KEY=<secret-access-key> -e AWS_SESSION_TOKEN=<session-token> -e AWS_DEFAULT_REGION=<region> aws-batch-single
```


