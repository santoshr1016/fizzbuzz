### Stage1 
#### Creating the Infrastructure using Terraform
```text
Launching AWS instance with Security Group in VPC with key-pair. 
Create mykey using the `ssh-keygen -f mykey`

Run terraform files by the following 
$ terraform init
$ terraform plan -out tfplan 
$ terraform apply tfplan
```

### Stage 2
#### Provision K8S using the Ansible
```text
In order to use ansible modify the dynamic inventory located at /etc/ansible/ansible.cfg and 
/etc/ansible/hosts as per the new ec2 instance as below

[local]
127.0.0.1 ansible_connection=local

[ec2]
XX.XX.XX.XX ansible_user=ubuntu
```

Run the following Ansible commands

```text
ansible all -m ping --ask-pass --ask-sudo-pass

export KUBERNETES_PROVIDER=aws

ansible-playbook k8s.yml --private-key = path/to/mykey

```
