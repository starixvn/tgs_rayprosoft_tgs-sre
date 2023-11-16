##kube命令補全
vi .bashrc
source <(kubectl completion bash)
source .bashrc

##create namespace
kubectl create  namespace XXX

# 安裝helm 
https://helm.sh/docs/intro/install/
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

### calico(k8s內部溝通之安全防護規則)
## https://docs.tigera.io/calico/3.25/getting-started/kubernetes/self-managed-onprem/onpremises

curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml -O
sed -i 's/# - name: CALICO_IPV4POOL_CIDR/- name: CALICO_IPV4POOL_CIDR\n              value: "172.16.0.0\/16"/g'  calico.yaml
kubectl apply -f calico.yaml

### ingress(k8s cluster對外通信)

#REF: https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal-clusters

#REF: https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm -n ingress-nginx upgrade -i nginx-ingress ingress-nginx/ingress-nginx -f values-ingress-controller.yaml

## 配置外部nginx.conf
apt install -y nginx
vi nginx.conf  #貼上設定檔,使用kubectl get svc -n ingress-nginx查看內部端口 並修改設定檔中upstream內的端口  ip為worker node的ip
systemctl restart nginx #之後將域名指向此nginx所在機器的IP後即可連線
#clone tgs-devops repository
git clone https://gitlab.com/rayprosoft/tgs-devops.git

### cert-manager
https://cert-manager.io/docs/installation/
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
kubectl apply -f test-environment/dev/k8s-install/_settings/cluster-issuer.yml ##安裝免費憑證製作
## 部屬metric-server(即pods的top功能)

wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
##因需要修改官方YAML 先下載後進入編輯
找到- --kubelet-preferred-address-types=InternalIP這行 下方新增
- --kubelet-insecure-tls 記得標頭要對齊
kubectl apply -f metrics-server.yaml
kubectl get pods -n kube-system |grep metrics ##驗證狀態是否為ready
kubectl top pods -n kube-system ##驗證是否正常運行

# reloader (在configmap或secret變動時自動reload pods)
https://github.com/stakater/Reloader
kubectl apply -f https://raw.githubusercontent.com/stakater/Reloader/master/deployments/kubernetes/reloader.yaml

# nfs provisioner(讓有儲存空間需求的服務切分空間使用)
(
apt update
apt install nfs-common -y
mkdir -p /nfsshare
mount -t nfs 192.168.50.111:/nfsshare /nfsshare
sed -i '$a192.168.50.111:/nfsshare /nfsshare nfs defaults 0 0' /etc/fstab
ls /nfsshare
)

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
  
helm repo update

helm upgrade -i nfs-provisioner \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=192.168.50.111 \
  --set nfs.path=/nfsshare \
  --set storageClass.name=nfs-provisioner
  


# rabbitmq
## https://www.rabbitmq.com/kubernetes/operator/operator-overview.html
## https://github.com/rabbitmq/cluster-operator/tree/main/docs/examples

kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml"

## go to k8s-installation/rabbitmq
kubectl create ns rabbitmq
kubectl apply -f rabbitmq.yaml
kubectl apply -f ingress.yaml

https://blog.csdn.net/qq_24095055/article/details/97001679

kubectl exec -it  mq-server-0 /bin/bash -n rabbitmq

rabbitmqctl add_vhost /tgs/dev
rabbitmqctl add_vhost /tgs/staging
rabbitmqctl add_vhost /tgs/prod

rabbitmqctl set_permissions -p "/tgs/dev" "tgs" '.*' '.*' '.*'
rabbitmqctl set_permissions -p "/tgs/staging" "tgs" '.*' '.*' '.*'
rabbitmqctl set_permissions -p "/tgs/prod" "tgs" '.*' '.*' '.*'
rabbitmqctl set_user_tags tgs administrator


# fluent-bit
#REF: https://docs.fluentbit.io/manual/installation/kubernetes#installation

helm repo add fluent https://fluent.github.io/helm-charts
helm repo update
cd fluentbit/
helm upgrade -i fluent-bit fluent/fluent-bit -f edge-values.yaml -n logging
helm template fluent-bit fluent/fluent-bit -f edge-values.yaml -n logging

# elasticsearch
kubectl create -f https://download.elastic.co/downloads/eck/2.10.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.10.0/operator.yaml
kubectl apply -f elasticsearch-eck-dev.yaml

#JAEGER (收集微服務間的通信速度跟資訊)
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.49.0/jaeger-operator.yaml -n observability  ##CRD for jaeger
kubectl apply -f jaeger-eck.yml
kubectl apply -f rbac-jaeger.yaml
kubectl apply -f jaeger/otel/
##nats安裝
#https://nats-io.github.io/k8s/
#https://github.com/nats-io/k8s/blob/main/helm/charts/nats/values.yaml
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm repo update
helm search repo nats
helm upgrade --install nats nats/nats -f values-nats.yaml -n dev

##promethus
kubectl -n monitoring create secret generic etcd-certs \
--from-file=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
--from-file=/etc/kubernetes/pki/etcd/healthcheck-client.key \
--from-file=/etc/kubernetes/pki/etcd/ca.crt 

export TOKEN=`kubectl -n monitoring exec -it prometheus-prometheus-stack-kube-prom-prometheus-0 -c prometheus -- cat /var/run/secrets/kubernetes.io/serviceaccount/token`

kubectl -n monitoring exec -it prometheus-prometheus-stack-kube-prom-prometheus-0 -- ls /etc/prometheus/secrets/etcd-certs
helm upgrade --install -f values.yaml prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring
# fix etcd
mv /etc/kubernetes/manifests/etcd.yaml ./
sleep 3
sed -i 's/listen-metrics-urls=http://127.0.0.1:2381/listen-metrics-urls=http://0.0.0.0:2381/g' etcd.yaml
mv etcd.yaml /etc/kubernetes/manifests/

# fix kube-scheduler
mv /etc/kubernetes/manifests/kube-scheduler.yaml ./
sleep 3
sed -i 's/bind-address=127.0.0.1/bind-address=0.0.0.0/g' kube-scheduler.yaml
mv kube-scheduler.yaml /etc/kubernetes/manifests/

# fix kube-controller-manager
mv /etc/kubernetes/manifests/kube-controller-manager.yaml ./
sleep 3
sed -i 's/bind-address=127.0.0.1/bind-address=0.0.0.0/g' kube-controller-manager.yaml
mv kube-controller-manager.yaml /etc/kubernetes/manifests/

# fix kube-proxy
kubectl -n kube-system get configmap kube-proxy -o yaml > cm-kube-proxy.yaml
sed -i 's/metricsBindAddress: ""/metricsBindAddress: "0.0.0.0"/g' cm-kube-proxy.yaml
kubectl apply -f cm-kube-proxy.yaml
kubectl -n kube-system delete pod -l k8s-app=kube-proxy
rm cm-kube-proxy.yaml

#grafana
已含在kube-prometus套建中
預設帳號 admin/prom-operator


#minio
curl -O https://raw.githubusercontent.com/minio/operator/master/helm-releases/operator-5.0.10.tgz
curl -O https://raw.githubusercontent.com/minio/operator/master/helm-releases/tenant-5.0.10.tgz

helm install \
--namespace minio-operator \
--create-namespace \
minio-operator operator-5.0.10.tgz
kubectl get service console -n minio-operator -o yaml > service.yaml
yq e -i '.spec.type="NodePort"' service.yaml
yq e -i '.spec.ports[0].nodePort = PORT_NUMBER' service.yaml
kubectl get deployment minio-operator -n minio-operator -o yaml > operator.yaml
yq -i -e '.spec.replicas |= 1' operator.yaml
------------------------------
vi console-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: console-sa-secret
  namespace: minio-operator
  annotations:
    kubernetes.io/service-account.name: console-sa
type: kubernetes.io/service-account-token
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: console-ingress
  namespace: minio-operator
spec:
  ingressClassName: nginx
  rules:
  - host: minio-bk.rpgp.cc
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: console
            port:
              number: 9090
----------------------------
kubectl apply -f service.yaml
kubectl apply -f operator.yaml
kubectl apply -f console-secret.yaml

uses a JWT to login
SA_TOKEN=$(kubectl -n minio-operator  get secret console-sa-secret -o jsonpath="{.data.token}" | base64 --decode)
echo $SA_TOKEN


