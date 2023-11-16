### install rabbitmq

https://www.rabbitmq.com/kubernetes/operator/operator-overview.html

kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml"

## install krew
https://krew.sigs.k8s.io/docs/user-guide/setup/install/

kubectl krew install rabbitmq
kubectl rabbitmq install-cluster-operator


## only use pv in dev env 
kubectl apply -f pv.yml


kubectl create ns rabbitmq
kubectl apply -f rabbitmq.yml
kubectl apply -f ingress.yml

https://blog.csdn.net/qq_24095055/article/details/97001679

kubectl exec -it  mq-server-0 /bin/bash -n rabbitmq


rabbitmqctl add_user tgs TgsP@ssw0rd

rabbitmqctl add_vhost /tgs/dev
rabbitmqctl add_vhost /tgs/staging
rabbitmqctl add_vhost /tgs/prod

rabbitmqctl set_permissions -p "/tgs/dev" "tgs" '.*' '.*' '.*'
rabbitmqctl set_permissions -p "/tgs/staging" "tgs" '.*' '.*' '.*'
rabbitmqctl set_permissions -p "/tgs/prod" "tgs" '.*' '.*' '.*'

rabbitmqctl set_user_tags tgs administrator


https://rabbitmq.rpgp.cc/



### changing node types 

kubectl exec -it mq-server-0 /bin/bash -n rabbitmq

rabbitmqctl cluster_status

rabbitmqctl change_cluster_node_type disc

rabbitmqctl change_cluster_node_type ram

rabbitmqctl stop_app

rabbitmqctl start_app


test