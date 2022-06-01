

lb=$(kubectl get svc -n istio-system -o yaml | yq '.items[].status[].ingress[].hostname')
echo 

for l in $lb;
do
  echo $l
  arn=$(aws elbv2 describe-load-balancers | jq -r --arg NAME "$l" '.LoadBalancers[] | select(.DNSName == $NAME) | .LoadBalancerArn' )
  echo "arn = $arn"
  aws elbv2 describe-load-balancers --load-balancer-arns $arn
  aws elbv2 describe-load-balancer-attributes --load-balancer-arn $arn
  aws elbv2 describe-listeners --load-balancer-arn $arn
  echo 
done
