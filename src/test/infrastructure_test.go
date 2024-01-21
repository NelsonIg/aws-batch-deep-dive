package test

import (
	"context"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestAWSBatch(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(
		t,
		&terraform.Options{
			TerraformDir: "../infrastructure",
			Vars: map[string]interface{}{
				"prefix":     "terratest",
				"subnet_ids": []string{"subnet-0b744b0a5d99ff299", "subnet-01a855ef14bcca1eb"},
				"vpc_id":     "vpc-0d62fcbdbfb61ede7",
			},
		},
	)

	// Clean up resources with "terraform destroy" at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)
	desiredBucketName := terraformOptions.Vars["prefix"].(string) + "-batch-deep-dive"
	assert.True(t, BucketExists(desiredBucketName), "Bucket with name %s does not exist", desiredBucketName)
}

func BucketExists(bucketName string) bool {
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		panic(err)
	}

	s3Client := s3.NewFromConfig(cfg)
	_, err = s3Client.HeadBucket(context.TODO(), &s3.HeadBucketInput{
		Bucket: aws.String(bucketName),
	})
	exists := true
	if err != nil {
		exists = false
	}
	return exists
}
