#!/bin/bash

###############
## Variables ##
###############

#shellcheck disable=SC1091
PROJECT_DIR=$(git rev-parse --show-toplevel)
SCRIPTS_DIR="$PROJECT_DIR/scripts"

if [[ -e "$PROJECT_DIR/00-variables.conf" ]]; then
  source "$PROJECT_DIR/00-variables.conf"
elif [[ -e "$SCRIPTS_DIR/00-variables.conf" ]]; then
  source "$SCRIPTS_DIR/00-variables.conf"
fi

## Loading creds
export AWS_PROFILE="$AWSAML_PROFILE"
export AWS_DEFAULT_PROFILE="$AWSAML_PROFILE"

# Create route53 entry
LB_ARN=$(\
  aws resourcegroupstaggingapi get-resources \
    --tag-filters Key=kubernetes.io/cluster/"$YOUR_CLUSTER_VALUE",Values=owned \
    --resource-type-filters elasticloadbalancing:loadbalancer \
    --tags-per-page 100 \
    --region us-east-1 \
    --no-cli-pager \
  | jq '.ResourceTagMappingList[0].ResourceARN' \
  | sed 's/"//g'\
)


LB_DNS_NAME=$(\
  aws elbv2 describe-load-balancers \
    --load-balancer-arns "$LB_ARN" \
    --region us-east-1 \
    --no-cli-pager \
  | jq '.LoadBalancers[0].DNSName' \
  | sed 's/"//g'\
)

aws route53 change-resource-record-sets --hosted-zone-id Z035959739Z0LUKSAJZYX --change-batch '
{
  "Comment": "CREATE a record ",
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "*.'"$YOUR_SUBDOMAIN"'.bahsoftwarefactory.com",
      "Type": "CNAME",
      "TTL": 60,
      "ResourceRecords": [{
        "Value": "'"$LB_DNS_NAME"'"
      }]
    }
  }]
}' --no-cli-pager


## Adding IP to Loadbalancer SG - ok if Classic LB then uncomment.
# LB_SG=$(\
#   aws elb describe-load-balancers \
#     --load-balancer-name "$LB_NAME" \
#     --region us-east-1 \
#     --no-cli-pager \
#   | jq '.LoadBalancerDescriptions[0].SecurityGroups[0]' \
#   | sed 's/"//g'\
# )
# YOUR_IP=$(curl ifconfig.me)
#
# aws ec2 authorize-security-group-ingress \
#   --group-id "$LB_SG" \
#   --ip-permissions IpProtocol=all,FromPort=-1,ToPort=-1,IpRanges='[{CidrIp='"$YOUR_IP"/32',Description='"$SG_DESCRIPTION"'}]' \
#   --region us-east-1 \
#   --no-cli-pager
