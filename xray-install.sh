#!/usr/bin/env bash
echo -e "提示：使用本脚本请使用root权限！"
echo -e "开始安装xray"


mkdirTools() {
	mkdir -p /usr/local/bin/xray
	mkdir -p /usr/local/bin/xray/conf
	mkdir -p /usr/local/bin/xray/log
}

mkdirTools

wget -O /usr/local/bin/xray/xray https://github.com/bejiba/Xray-ws/raw/main/xray
wget -O /usr/local/bin/xray/geosite.dat https://github.com/bejiba/Xray-ws/raw/main/geosite.dat
wget -O /usr/local/bin/xray/geoip.dat https://github.com/bejiba/Xray-ws/raw/main/geoip.dat
chmod +x /usr/local/bin/xray/xray

#wget --no-check-certificate -O "Xray-ws-main.tar.gz" https://github.com/bejiba/Xray-ws/archive/refs/heads/main.zip
#unzip "Xray-ws-main.tar.gz"

# 将当前root/Xray-ws-main目录下的所有文件拷贝到/usr/local/bin/xray
cp -r Xray-ws-main/* /usr/local/bin/xray

#删除Xray-ws-main.tar.gz以及解压后的文件Xray-ws-main
#rm -rf Xray-ws-main Xray-ws-main.tar.gz

# Xray Installation
cat <<EOF > /etc/systemd/system/xray.service
[Unit]
Description=Xray - A unified platform for anti-censorship
# Documentation=https://v2ray.com https://guide.v2fly.org
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=yes
ExecStart=/usr/local/bin/xray/xray run -confdir /usr/local/bin/xray/conf
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xray

# Xray Configuration
cat <<EOF > /usr/local/bin/xray/conf/config.json
{
  "log" : {
    "loglevel": "warning"
  },
"inbounds":[
{
  "port": 80,
  "protocol": "vless",
  "settings": {
    "clients": [
     {
        "id": "3583bea4-628e-492c-b19c-6fb34f149757"
      }
    ],
    "decryption": "none",
    "fallbacks": [
        {"dest":31296,"xver":1},{"path":"//ws","dest":31297,"xver":1}
    ]
  },
   "streamSettings": {
    "network": "tcp"
        },
    "sniffing": {
    "enabled": true,
    "destOverride": [
     "http",
     "tls"
    ]
   }
},
{
  "port": 31296,
  "listen": "127.0.0.1",
  "protocol": "vless",
  "tag":"VLESSWS",
  "settings": {
    "clients": [
      {
        "id": "3583bea4-628e-492c-b19c-6fb34f149757"
      }
    ],
    "decryption": "none"
  },
  "streamSettings": {
    "network": "ws",
    "security": "none",
    "wsSettings": {
      "acceptProxyProtocol": true
    }
  }
},
{
  "port": 31297,
  "protocol": "vmess",
  "tag":"VMessTCP",
  "settings": {
    "clients": [
      {
        "id": "3583bea4-628e-492c-b19c-6fb34f149757",
        "alterId": 1
      }
    ]
  },
  "streamSettings": {
    "network": "ws",
    "security": "none",
    "wsSettings": {
      "acceptProxyProtocol": true,
      "path": "//ws"
    }
  }
}
],
"outbounds": [
        {
          "protocol": "freedom",
          "settings": {
            "domainStrategy": "UseIPv4"
          },
          "tag": "IPv4-out"
        },
        {"tag": "VPS1",
        	"protocol": "vmess",        // 出口协议
      "settings": {
        "vnext": [
          {
            "address": "******", // 国外服务器地址
            "port": 80,        // 国外服务器端口
            "users": [
                {"id": "3583bea4-628e-492c-b19c-6fb34f149757",
                 "alterId": 0  } // 用户 ID，须与国外服务器端配置相同
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws"
      }
    },
    {
			"protocol": "blackhole",
			"settings": {},
			"tag": "blocked"
        }
    ],
    "dns": {
              "servers": [
                          "localhost"
  ]
},
"routing": { // 路由设置
    "rules": [
      {"type": "field",
        "outboundTag": "VPS1",
        "domain": [
        "geosite:CATEGORY-PORN",
        "geosite:pornhub",
        "geosite:apple-cn",
        "geosite:netflix",
        "geosite:telegram"         
       ] // netflix 走 VPS1
      },
{
      "type": "field",
      "outboundTag": "VPS1",
      "ip": [
        "geoip:telegram"
      ]
    },
      {
				"type": "field",
				"ip": [
					"0.0.0.0/8",
					"10.0.0.0/8",
					"100.64.0.0/10",
					"127.0.0.0/8",
					"169.254.0.0/16",
					"172.16.0.0/12",
					"192.0.0.0/24",
					"192.0.2.0/24",
					"192.168.0.0/16",
					"198.18.0.0/15",
					"198.51.100.0/24",
					"203.0.113.0/24",
					"::1/128",
					"fc00::/7",
					"fe80::/10"
				],
				"outboundTag": "blocked"
			},
			{
				"type": "field",
				"inboundTag": ["tg-in"],
				"outboundTag": "tg-out"
			}
       ]
  },
  "transport": {
		"kcpSettings": {
            "uplinkCapacity": 100,
            "downlinkCapacity": 100,
            "congestion": true
        }
	}    
}

EOF

echo -e "默认路径：/usr/local/bin/xray"
echo -e "重启xray指令：systemctl restart xray"
systemctl restart xray
echo -e "查看xray状态：systemctl status xray"
systemctl status xray
