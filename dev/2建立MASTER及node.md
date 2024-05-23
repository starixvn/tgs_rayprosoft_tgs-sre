##set timezone
timedatectl set-timezone Asia/Taipei
## Disable swap
```
swapoff -a; sed -i '/swap/d' /etc/fstab
```
## Disable Firewall
```
systemctl disable --now ufw
```
## Enable and Load Kernel modules
```
{
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
}
```

## Add Kernel settings
```
{
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
}
```


## Install Containerd
https://github.com/containerd/containerd/blob/main/docs/getting-started.md
https://docs.docker.com/engine/install/ubuntu/
```
{
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
 
sudo apt-get update
sudo apt-get install containerd.io

containerd config default > /etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

systemctl restart containerd
}
```

## Add apt repo for kubernetes
```
{
apt-get update && sudo apt-get install -y apt-transport-https curl
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

}
```

## Install Kubernetes components
```
{
  apt update
  apt install -y kubeadm kubelet kubectl
}
```

kubectl get node ##檢查是否創建成功
  
 

kubeadm init --kubernetes-version=1.28.2 --apiserver-advertise-address=192.168.50.3 --control-plane-endpoint=192.168.50.3 --pod-network-cidr=10.160.0.0/16 --upload-certs ##集群初始化參數&命令列表

  kubeadm join 192.168.50.74:6443 --token j1xxpn.0pws5tmoiclmycfq \
	--discovery-token-ca-cert-hash sha256:f3aa4c2905bb586e4e45c8dc6003394857b8c8f3458281e60f888ea2ebfeb65c \
	--control-plane --certificate-key 025be9bfbd2e3062a3309c9f079b5b7ffe712769cacd5b12b5a7bb60f43215cc               ##master加入cluster指令

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.50.74:6443 --token j1xxpn.0pws5tmoiclmycfq \
	--discovery-token-ca-cert-hash sha256:f3aa4c2905bb586e4e45c8dc6003394857b8c8f3458281e60f888ea2ebfeb65c ##workernode加入master節點指令,node完成上面基礎配置之後直接使用這串命令加入cluster就可以了,記得確認是否ready,join完之後要啟動kubelet
	
	kubeadm init phase upload-certs --upload-certs ##control plane憑證過期重新生成  產出的值替換掉--control-plane --certificate-key後面的值
	
	


kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.tigera.io/archive/v3.25/manifests/calico.yaml ##安裝COREDNS+CALICO配置叢集網路環境

kubectl label nodes worker1 node-role.kubernetes.io/worker=worker