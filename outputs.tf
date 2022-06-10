output "lambda_invoke_arn" {
  value       = aws_lambda_function.lambda_function.invoke_arn
  description = "Invoke ARN of the AWS Lambda."
}

output "s3_bucket_id" {
  value       = aws_s3_bucket.yaml_parsor_bucket.id
  description = "ID of the S3 bucket."
}
