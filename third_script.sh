#!/bin/bash
source /home/ubuntu/acatest/third_script/aws_credentials
source /home/ubuntu/acatest/third_script/function
aws configure set aws_access_key_id $access_key
aws configure set aws_secret_access_key $secret_key
aws configure set region "$ec2_region"

echo "$dst_folder"
src_file=/etc/apt/sources.list
sudo cp -f $src_file $dst_folder
echo "https://www.test.com/testurl" >> $dst_folder/sources.list

awk '/http/ { print }' sources.list > $dst_folder/source_tmp

filter_http 
sed 's/ main/ universe/; s/^.*\(http:*\)/\1/ ; s/^.*\(https:*\)/\1/ ; s/https:/httpd:/ ; s/http:/https:/ ; s/httpd:/http:/' source_tmp > $dst_folder/source_cleared

cat $dst_folder/source_cleared 

line_count=$(wc -l $dst_folder/source_cleared | awk '{print $1}')
echo $line_count
file_sep
#for i in $(seq 1 ${line_count})
#do
#	sed -n "${i}p" $dst_folder/source_cleared > file$i
#done
upload
#for j in $(seq 1 ${line_count})
#do
#	aws s3 cp $dst_folder/file$j s3://second-scripst-321 --region "us-east-1"
#done
