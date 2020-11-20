terraform{
    required_version =">0.12"
    backend "s3" {
        bucket = "tfbackendbucket"
        key = "terraform-backend/terraform.tfstate"
        region = "us-east-1"
    }
}
