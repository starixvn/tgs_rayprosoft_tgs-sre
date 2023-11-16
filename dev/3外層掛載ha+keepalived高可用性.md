apt install -y keepalived haproxy
vi /etc/haproxy/haproxy.cfg
global
    log /dev/log  local0 warning
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

   stats socket /var/lib/haproxy/stats

defaults
  log global
  option  httplog
  option  dontlognull
        timeout connect 5000
        timeout client 50000
        timeout server 50000

frontend kube-apiserver
  bind *:6443
  mode tcp
  option tcplog
  default_backend kube-apiserver

backend kube-apiserver
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    server kube-apiserver-1 172.16.0.4:6443 check # Replace the IP address with your own.
    server kube-apiserver-2 172.16.0.5:6443 check # Replace the IP address with your own.
    server kube-apiserver-3 172.16.0.6:6443 check # Replace the IP address with your own.
	
	
	systemctl restart haproxy
systemctl enable haproxy

vi /etc/keepalived/keepalived.conf
global_defs {
  notification_email {
  }
  router_id LVS_DEVEL
  vrrp_skip_check_adv_addr
  vrrp_garp_interval 0
  vrrp_gna_interval 0
}

vrrp_script chk_haproxy {
  script "killall -0 haproxy"
  interval 2
  weight 2
}

vrrp_instance haproxy-vip {
  state BACKUP
  priority 100
  interface eth0                       # Network card
  virtual_router_id 60
  advert_int 1
  authentication {
    auth_type PASS
    auth_pass 1111
  }
  unicast_src_ip 172.16.0.2      # The IP address of this machine
  unicast_peer {
    172.16.0.3                         # The IP address of peer machines
  }

  virtual_ipaddress {
    172.16.0.10/24                  # The VIP address
  }

  track_script {
    chk_haproxy
  }
}
对于 interface 字段，您必须提供自己的网卡信息。您可以在机器上运行 ifconfig 以获取该值。

为 unicast_src_ip 提供的 IP 地址是您当前机器的 IP 地址。对于也安装了 HAproxy 和 Keepalived 进行负载均衡的其他机器，必须在字段 unicast_peer 中输入其 IP 地址。

systemctl restart keepalived
systemctl enable keepalived
