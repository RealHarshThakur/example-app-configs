data "archive_file" "handler" {
  type        = "zip"
  output_path = "${path.module}/handler.zip"

  source {
    filename = "handler.py"
    content  = <<-PY
      import json

      # In-memory counters. Persist across warm invocations of the same
      # execution environment; reset on cold start and not shared across
      # concurrent environments. Sufficient for a demo, not for real state.
      _counts = {}

      def handler(event, context):
          widget = (event.get("pathParameters") or {}).get("id", "default")
          _counts[widget] = _counts.get(widget, 0) + 1
          return {
              "statusCode": 200,
              "headers": {"Content-Type": "application/json"},
              "body": json.dumps({"widget": widget, "count": _counts[widget]}),
          }
    PY
  }
}

module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.0"

  function_name = var.function_name
  handler       = "handler.handler"
  runtime       = "python3.13"

  create_package         = false
  local_existing_package = data.archive_file.handler.output_path

  cloudwatch_logs_retention_in_days = 3
  logging_log_group                 = "/aws/lambda/${var.install_id}/${var.function_name}"
}
