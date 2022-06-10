# # -----------------------------------
# # S3 Bucket
# # -----------------------------------

resource "aws_s3_bucket" "yaml_parsor_bucket" {
  bucket = "${var.resource_names_prefix}-yaml-parsor"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  bucket = aws_s3_bucket.yaml_parsor_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# # -----------------------------------
# # S3 Bucket - Security
# # -----------------------------------

resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  bucket = aws_s3_bucket.yaml_parsor_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_encryption_configuration" {
  bucket = aws_s3_bucket.yaml_parsor_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access" {
  bucket = aws_s3_bucket.yaml_parsor_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# # -----------------------------------
# # S3 Bucket - Files
# # -----------------------------------
resource "aws_s3_object" "yaml_object" {
  bucket     = aws_s3_bucket.yaml_parsor_bucket.id
  key        = "input.yaml"
  source     = "./input.yaml"
  etag       = filemd5("${path.root}/input.yaml")
  depends_on = [aws_s3_bucket.yaml_parsor_bucket]
}

# # -----------------------------------
# # Lambda - CloudWatch Logging
# # -----------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "${var.resource_names_prefix}-lambda-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_policy" "lambda_role_policy" {
  name        = "${var.resource_names_prefix}-lambda-role-policy"
  description = "Policy attached to the Lambda for logging to CloudWatch."
  tags        = var.tags
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:PutObject",
          "s3:GetObject"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_role_policy.arn
}

# # -----------------------------------
# # Lambda - Function
# # -----------------------------------
resource "aws_lambda_function" "lambda_function" {
  filename         = "main.zip"
  function_name    = "${var.resource_names_prefix}-lambda-function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/main.zip")
  tags             = var.tags
}

# -----------------------------------
# Lambda - Access
# This provides external permission for LAMBDA to access S3.
# -----------------------------------
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = aws_s3_bucket.yaml_parsor_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".yaml"

  }
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowOSAPILambdaAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.resource_names_prefix}-lambda-function"
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.yaml_parsor_bucket.id}"
}
