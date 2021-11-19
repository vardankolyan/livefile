#!/bin/bash -x

domain_name=vardan.acadevopscourse.xyz
path=/home/ubuntu/acatest/livefile/cloudfront
#create S# bucket with domain name url

aws s3api create-bucket --bucket $domain_name --region "us-east-2" --acl public-read --create-bucket-configuration LocationConstraint=us-east-2

echo "<p><em>Example site for aca course</em></p> 
<p><em>s3_image_url<img src="https://${domain_name}/s3.amazonaws.com/devops.jpg" alt="Devops" width="300" height="300" /></em></p>" > $path/index.html

aws s3 cp $path/devops.jpg s3://$domain_name --region "us-east-2" --acl public-read
aws s3 cp $path/index.html s3://$domain_name --region "us-east-2" --acl public-read
#geting VPC ID
vpc_id=$(aws ec2 describe-vpcs --region us-east-2 | jq -r .Vpcs[].VpcId)
#creating target group
aws elbv2 create-target-group --name lb-instance --protocol HTTP    --port 80  --target-type instance --vpc-id $vpc_id --region us-east-2
#get target ARN
target_arn=$(jq -r .TargetGroups[].TargetGroupArn ./target.json)
#register target groups
#instance_id=get-instance
aws elbv2 register-targets --target-group-arn $target_arn --targets Id=$instance_id --region us-east-2 
#get subnet IDs
subnet_id=$(aws ec2 describe-subnets --region us-east-2 | jq -r .Subnets[].SubnetId)
#security Group ID
sec_grp=$(aws ec2 describe-security-groups --filters Name=group-name,Values=launch-wizard-2   --region us-east-2 | jq -r .SecurityGroups[].GroupId)
#create load balancer
lb_domain_name=$(aws elb create-load-balancer --load-balancer-name my-load-balancer --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" --subnets $subnet_id --security-groups $sec_grp --region us-east-1 | jq -r .LoadBalancers[].DNSName)
#create cloudfront
#get certificate id
cert_id=$(aws iam list-server-certificates | jq -r .ServerCertificateMetadataList[].ServerCertificateId)

aws cloudfront create-distribution  --origin-domain-name ${domain_name}.s3.amazonaws.com --default-root-object index.html > cf_out.json

dist_id=$(jq -r .Distribution.Id cf_out.json)
cf_domain_name=$(jq -r .Distribution.DomainName cf_out.json)
aws cloudfront associate-alias --target-distribution-id $dist_id --alias $domain_name
aws cloudfront associate-alias --target-distribution-id $dist_id --alias www.$domain_name
aws iam update-server-certificate --server-certificate-name new.vardan.acadevopscourse.xyz --new-path /cloudfront/$dist_id/
aws cloudfront update-distribution --id $dist_id 

#crewate DNS record
sed -i "s/$lb_name/${lb_domain_name}/g" route53_in.json
sed -i "s/$cf_name/${cf_domain_name}/g" route53_in.json
aws route53 change-resource-record-sets --hosted-zone-id Z03074001EGS3T9A5ZEF6  --change-batch file://route53_in.json

