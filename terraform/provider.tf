provider "aws" {
  alias  = "selected_region"
  region = "${var.region}"
}
