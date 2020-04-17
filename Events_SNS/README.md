## How to run
```text
Change the region and put the region specific AMI id, otherwise you will get error

terraform init
terraform plan -o tfplan
terraform apply tfplan

Output

Confirm the email subscription of the topic

It will create SNS Topic name : Santosh-Alarm-101
It will create an EC2 instance : Santosh-Alarm-101
It will create 2 Alarms:
high-cpu-utilization-alarm
instance-health-check
```