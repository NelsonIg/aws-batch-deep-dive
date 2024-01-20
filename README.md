# aws-batch-deep-dive
A hands-on dive into AWS Batch.

## Prerequisites
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) and Credentials to an AWS Account with Permissions to create resources
- [Terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform)
- [Docker](https://docs.docker.com/get-docker/)
- [Python](https://www.python.org/downloads/)

## Setup
1. Clone this repository
2. Deploy the infrastructure using Terraform  
    2.1 Navigate to the infrastructuresrc directory
    ```bash
    cd src/infrastructure/
    ``````
    2.2 You need a VPC and Security Groups, take note of the VPC ID and Security Group IDs in order to pass them to the apply command. Use the prefix variable to create custom names for the resources.
    ```bash
    terraform init
    terraform plan -var prefix=<prefix> -var 'subnet_ids=["<subnet-1>", "<subnet-2>"]' -var vpc_id=<vpc-id> -out tfplan
    ``````
    2.3 Verify the plan and apply it if it looks good.
    Resources that are to be created:
    - S3 Bucket that will be used as source and destination for the batch jobs
    - ECR Repository to store the docker image
    - Security Group for the ECS Task hosting the docker image/ Batch Job
    - IAM Roles and Policies for the Batch Job and ECS Task
    - AWS Batch Compute Environment
    - AWS Batch Job Queue
    - AWS Batch Job Definition
    Apply the plan:
    ```bash
    terraform apply tfplan
    ````
    2.4 Take a look at the resources that have been created in the AWS Console.
    - [AWS Batch](https://eu-central-1.console.aws.amazon.com/batch/home?region=eu-central-1)
    - [ECR](https://eu-central-1.console.aws.amazon.com/ecr/repositories?region=eu-central-1)
    - [S3](https://s3.console.aws.amazon.com/s3/home?region=eu-central-1)

3. Build the docker image and push it to ECR. 
    3.1 Login to ECR
    ```bash
    aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 266154869614.dkr.ecr.eu-central-1.amazonaws.com
    ```
    url is in the form of `<account-id>.dkr.ecr.<region>.amazonaws.com`
    
    3.2 Build Image  
    Change directory to the Dockerfile location. [Dockerfile](src/python/single/Dockerfile)
    ```bash
    cd ../python/single/
    ```
    When on Mac M1, you need to use the `--platform linux/amd64` flag to build the image for the correct architecture.
    ```bash
    docker build --platform linux/amd64 -t <ecr-name> .
    ```
    
    otherwise, just use
    ```bash
    docker build -t <ecr-name> .
    ```
    
    3.3 Tag Image
    ```bash
    docker tag <ecr-name>:latest <ecr-uri>:latest
    ```
    uri is in the form of `<account-id>.dkr.ecr.<region>.amazonaws.com/<ecr-name>`
    
    3.4 Push Image
    ```bash
    docker push <ecr-uri>:latest
    ```
4. Unpack the data and upload to S3  
    4.1. Change the directory
    ```bash
    cd ../../data/     
    ```
    4.2. Unpack the data with the command below or any other tool of your choice.
    ```bash
    unzip data.zip
    ```
    4.3. Upload the data to the S3 bucket that has been created by Terraform.
    ```bash
    aws s3 cp data s3://<bucket_name>/source --recursive
    ```
## 5. Run the job
You will submit a job to AWS Batch that will run the python script on the data that you have uploaded to S3. After the job has finished, you will find the results in the destination folder in the S3 bucket. The source and destination will be passed as arguments to the job.

5.1 Command to submit the job:
```bash
aws batch submit-job --job-name <job-name> --job-queue <job-queue> --job-definition <job-definition> --container-overrides command='["python", "script.py"]' --container-overrides environment='[{name="BUCKET",value="<bucket-name>"},{name=PREFIX,value="source"},{name="OUTPUT_PREFIX",value="output"}]'
```
5.2 View the job in the [AWS Batch Console](https://eu-central-1.console.aws.amazon.com/batch/home?region=eu-central-1#/jobs)  
5.3. Check the ECS Cluster where the Job is being executed. [ECS Console](https://eu-central-1.console.aws.amazon.com/ecs/home?region=eu-central-1#/clusters). A task will spin up and execute the job.  
5.4. Check the S3 bucket for the results. [S3 Console](https://s3.console.aws.amazon.com/s3/home?region=eu-central-1)

## Clean up  
Change to the infrastructure directory and run the destroy command.
```bash
cd ../infrastructure/  
terraform plan -var prefix=<prefix> -var 'subnet_ids=["<subnet-1>", "<subnet-2>"]' -var vpc_id=<vpc-id> -destroy -out tfplan
``````
Verify the plan and apply it if it looks good.
```bash
terraform apply tfplan
````

