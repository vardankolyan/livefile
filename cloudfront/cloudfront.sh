#!/bin/bash -x

domain_name=vardan.acadevopscourse.xyz
path=/home/ubuntu/acatest/livefile/cloudfront
#create S# bucket with domain name url

aws s3api create-bucket --bucket $domain_name --region "us-east-2" --acl public-read --create-bucket-configuration LocationConstraint=us-east-2
#create index.html file with jpg link
echo "<p><em>Example site for aca course</em></p> 
<p><em>s3_image_url<img src="https://${domain_name}/s3.amazonaws.com/devops.jpg" alt="Devops" width="300" height="300" /></em></p>" > $path/index.html
#upload files to bucket
aws s3 cp $path/devops.jpg s3://$domain_name --region "us-east-2" --acl public-read
aws s3 cp $path/index.html s3://$domain_name --region "us-east-2" --acl public-read
#geting VPC ID
vpc_id=$(aws ec2 describe-vpcs --region us-east-2 | jq -r .Vpcs[].VpcId)
#creating target group
aws elbv2 create-target-group --name lb-instance --protocol HTTP    --port 80  --target-type instance --vpc-id $vpc_id --region us-east-2 > $path/trg.out.json
#get target group ARN
target_arn=$(jq -r .TargetGroups[].TargetGroupArn $path/trg.out.json)
#getting instance id
instance_id=$(aws ec2 describe-instances --region us-east-2 | jq -r .Reservations[].Instances[].InstanceId)
#register instance under target
aws elbv2 register-targets --target-group-arn $target_arn --targets Id=$instance_id --region us-east-2 
#get subnet IDs
subnet_id=$(aws ec2 describe-subnets --region us-east-2 | jq -r .Subnets[].SubnetId)
#getting security Group ID
sec_grp=$(aws ec2 describe-security-groups --filters Name=group-name,Values=launch-wizard-2   --region us-east-2 | jq -r .SecurityGroups[].GroupId)
#create load balancer
lb_arn=$(aws elbv2 create-load-balancer --name my-load-balancer  --subnets $subnet_id --security-groups $sec_grp --region us-east-2 | jq -r .LoadBalancers[].LoadBalancerArn)
#getting load balancer domain name
lb_domain_name=$(aws elbv2 describe-load-balancers --load-balancer-arns $lb_arn --region us-east-2 | jq -r .LoadBalancers[].DNSName)
#create listener
aws elbv2 create-listener --load-balancer-arn $lb_arn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$target_arn --region us-east-2
#getting uploaded certificate id
cert_id=$(aws iam list-server-certificates | jq -r .ServerCertificateMetadataList[].ServerCertificateId)
#updating cloudfront distribution config json with certificate id to enable CNAMEs
sed "s/string/${cert_id}/g" $path/cf_dist.in.tmp.json > $path/cf_dist.in.json
#creating CloudFront distribution using json file
aws cloudfront create-distribution --distribution-config file://cf_dist.in.json > $path/cf_dist.out.json
#getting cloudfront distribution id
dist_id=$(jq -r .Distribution.Id cf_dist.out.json)
#waiting for distribution to be created
aws cloudfront wait distribution-deployed --id $dist_id
#getting cloudfront distribution domain name
cf_domain_name=$(jq -r .Distribution.DomainName cf_dist.out.json)
#Creating Route53 config file from tamplate
cp $path/route53.in.tmp.json $path/route53.in.json
#updating Route53 json file with LB and CF domain names
sed -i "s/loadbalancer_name/${lb_domain_name}/g" route53.in.json
sed -i "s/cloudfront_name/${cf_domain_name}/g" route53.in.json
#adding route53 records to hosted zone
aws route53 change-resource-record-sets --hosted-zone-id Z03074001EGS3T9A5ZEF6  --change-batch file://route53.in.json --region us-east-2
