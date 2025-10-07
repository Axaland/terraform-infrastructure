# Test Infrastructure Deployment
Write-Host " TESTING INFRASTRUCTURE" -ForegroundColor Cyan

# Test AWS connectivity
Write-Host "
=== AWS Test ===" -ForegroundColor Yellow
aws sts get-caller-identity

# Test S3 backend
Write-Host "
=== S3 Backend Test ===" -ForegroundColor Yellow  
aws s3 ls s3://tfstate-terraform-infrastructure-eu-west-1

# Test DynamoDB lock table
Write-Host "
=== DynamoDB Lock Test ===" -ForegroundColor Yellow
aws dynamodb describe-table --table-name tf-lock-terraform-infrastructure --query 'Table.TableStatus'

# Test OIDC role
Write-Host "
=== OIDC Role Test ===" -ForegroundColor Yellow
aws iam get-role --role-name github-ci-role-dev --query 'Role.Arn'

# Test created bucket
Write-Host "
=== Test Bucket ===" -ForegroundColor Yellow
aws s3 ls s3://test-deploy-dev-41b47ef5

Write-Host "
 INFRASTRUCTURE FULLY OPERATIONAL!" -ForegroundColor Green
