# Usage
## Initialize
```bash
terraform init
```

## Plan Appply
```bash
terraform plan -var prefix=<prefix> -var 'subnet_ids=["<subnet-1>", "<subnet-2>"]' -var vpc_id=<vpc-id> -out tfplan
```

## Plan Destroy
```bash
terraform plan -var prefix=<prefix> -var 'subnet_ids=["<subnet-1>", "<subnet-2>"]' -var vpc_id=<vpc-id> -destroy -out tfplan
```

## Apply Plan
```bash
terraform apply tfplan
```

## Push Image to ECR
### Login to ECR
```bash
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <ecr-url>
```
url is in the form of `<account-id>.dkr.ecr.<region>.amazonaws.com`

### Build Image
Change directory to the Dockerfile location. [Dockerfile](../python/single/Dockerfile)
When on Mac M1, you need to use the `--platform linux/amd64` flag to build the image for the correct architecture.
```bash
docker build --platform linux/amd64 -t <ecr-name> .
```

otherwise, just use
```bash
docker build -t <ecr-name> .
```

### Tag Image
```bash
docker tag <ecr-name>:latest <ecr-uri>:latest
```
uri is in the form of `<account-id>.dkr.ecr.<region>.amazonaws.com/<ecr-name>`

### Push Image
```bash
docker push <ecr-uri>:latest
```
