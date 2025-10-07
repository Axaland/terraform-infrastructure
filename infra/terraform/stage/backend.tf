terraform {
	backend "s3" {
		bucket         = ""
		key            = "env/stage/terraform.tfstate"
		region         = "eu-west-1"
		dynamodb_table = ""
		encrypt        = true
	}
}