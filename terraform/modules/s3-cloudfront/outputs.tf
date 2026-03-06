output "bucket_name" { value = aws_s3_bucket.frontend.bucket }
output "cloudfront_url" { value = "https://${aws_cloudfront_distribution.frontend.domain_name}" }
output "cloudfront_id" { value = aws_cloudfront_distribution.frontend.id }

