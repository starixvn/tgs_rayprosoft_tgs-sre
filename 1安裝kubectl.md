為什麼要先安裝kubectl?
kubectl為連線至k8s叢集之工具 一切k8s之操作都要這個指令動作 可以理解為k8s中的systemctl

---------------------------------------------------------------
start:
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
##如果正常會顯示kubectl: OK

##安裝kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

##創建.KUBE資料夾
chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl

##檢查版本
kubectl version --client

##設定KUBECONFIG
cd .kube
vi config #貼上要連線之K8S CLUSTER的CONFIG 沒問題就能連線了

#連線AWS的話要先裝AWS CLI
然後輸入API KEY跟金鑰以及地區

finish
--------------------------------------------------------------

剛開始時可能有現有地端開發環境可以摸
成功連線後可以試試幾個指令大概熟悉一下
kubectl get node  ##node就是一台機器 所有的pod等服務都是依靠於node的硬體資源運做
kubectl  top nodes ##查看nodes的機器狀態
kubectl get ns    ##ns=namespace 可以想像成分類群組名稱
kubectl get pods -n ns  ##查看指定ns下的pod總覽
kubectl get deploy -n ns ##查看指定ns下的deploy總攬
kubectl get pods lobby-t1 -n dev -o yaml ##指定查看在dev這個ns下名為lobby-t1這個pods的yaml檔
kubectl logs XXXXXX -n dev ##查看logs
kubectl describe  XXXXXX -n dev ##查看描述
kubectl get pods -n dev --sort-by=cpu, memory ##查看pods的使用資源