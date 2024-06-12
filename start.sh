#!/bin/bash

RED='\033[0;31m'
PLAIN='\033[0m'
GREEN='\033[0;32m'
Yellow="\033[33m";

proxy_info_file="ja3_proxy_info.txt"
log="unlock-chatgpt-test-result.log"

function check_dependencies() {
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "curl is not installed. Installing curl..."
        if command -v yum &> /dev/null; then
            sudo yum install curl -y
        elif command -v apt-get &> /dev/null; then
            sudo apt-get install curl -y
        else
            echo "Your system package manager is not supported. Please install curl manually."
            exit 1
        fi
    fi

    # Check if grep is installed
    if ! command -v grep &> /dev/null; then
        echo "grep is not installed. Installing grep..."
        if command -v yum &> /dev/null; then
            sudo yum install grep -y
        elif command -v apt-get &> /dev/null; then
            sudo apt-get install grep -y
        else
            echo "Your system package manager is not supported. Please install grep manually."
            exit 1
        fi
    fi

    # 检查docker-compose是否安装
    if ! command -v docker-compose &> /dev/null; then
        echo "docker-compose is not installed. Installing docker-compose..."
        curl -fsSL https://get.docker.com | bash -s docker
    fi
}

function UnlockChatGPTTest() {
    clear;
    echo -e "${GREEN}** Chat GPT ip可用性检测${PLAIN} ${Yellow}by JCNF·那坨${PLAIN}" && echo -e "Chat GPT ip可用性检测 by JCNF·那坨" > ${log};
    echo -e "${RED}** 提示 本工具测试结果仅供参考，请以实际使用为准${PLAIN}" && echo -e "提示 本工具测试结果仅供参考，请以实际使用为准" >> ${log};
    echo -e "** 系统时间: $(date)" && echo -e " ** 系统时间: $(date)" >> ${log};
    if [[ $(curl --max-time 10 -sS https://chat.openai.com/ -I | grep "text/plain") != "" ]]
    then
        local ip="$(curl -s http://checkip.dyndns.org | awk '{print $6}' | cut -d'<' -f1)"
        echo -e " 抱歉！本机IP：${ip} ${RED}目前不支持ChatGPT IP is BLOCKED${PLAIN}" | tee -a $log
    else
        local countryCode="$(curl --max-time 10 -sS https://chat.openai.com/cdn-cgi/trace | grep "loc=" | awk -F= '{print $2}')";
        if [ $? -eq 1 ]; then
            echo -e " ChatGPT: ${RED}网络连接失败 Network connection failed${PLAIN}" | tee -a $log
        fi
    fi
    if [ -n "$countryCode" ]; then
        support_countryCodes=(T1 XX AL DZ AD AO AG AR AM AU AT AZ BS BD BB BE BZ BJ BT BA BW BR BG BF CV CA CL CO KM CR HR CY DK DJ DM DO EC SV EE FJ FI FR GA GM GE DE GH GR GD GT GN GW GY HT HN HU IS IN ID IQ IE IL IT JM JP JO KZ KE KI KW KG LV LB LS LR LI LT LU MG MW MY MV ML MT MH MR MU MX MC MN ME MA MZ MM NA NR NP NL NZ NI NE NG MK NO OM PK PW PA PG PE PH PL PT QA RO RW KN LC VC WS SM ST SN RS SC SL SG SK SI SB ZA ES LK SR SE CH TH TG TO TT TN TR TV UG AE US UY VU ZM BO BN CG CZ VA FM MD PS KR TW TZ TL GB)
        if [[ "${support_countryCodes[@]}"  =~ "${countryCode}" ]];  then
            local ip="$(curl -s http://checkip.dyndns.org | awk '{print $6}' | cut -d'<' -f1)"
            echo -e " 恭喜！本机IP:${ip} ${GREEN}支持ChatGPT Yes (Region: ${countryCode})${PLAIN}" | tee -a $log
        else
            echo -e " ChatGPT: ${RED}No${PLAIN}" | tee -a $log
        fi
    else
        echo -e " ChatGPT: ${RED}Failed${PLAIN}" | tee -a $log
    fi

    echo "Press Enter to return to menu..."
    read
}

function deployJA3() {

    # 获取当前服务器的公网IP
    server_ip=$(curl -s http://checkip.dyndns.org | awk '{print $6}' | cut -d'<' -f1)

    # 检查是否成功获取到服务器的公网IP
    if [ -z "$server_ip" ]; then
        echo "无法获取服务器的公网IP，脚本退出。"
        exit 1
    else
        echo "服务器的公网IP为: $server_ip"
    fi

    # 生成随机端口函数
    generate_random_port() {
        echo $((2000 + RANDOM % 63001))
    }

    # 生成随机字符串函数
    generate_random_string() {
        cat /dev/urandom | tr -dc 'a-z0-9' | fold -w ${1:-16} | head -n 1
    }

    check_http_port() {
        while ss -tuln | awk '{print $5}' | grep -q ":$http_port$"
        do
            echo "端口$http_port已被占用，正在生成新的端口..."
            http_port=$(generate_random_port)
        done
        echo "HTTP端口: $http_port"
    }

    check_ja3_port() {
        while ss -tuln | awk '{print $5}' | grep -q ":$ja3_port$"
        do
            echo "端口$ja3_port已被占用，正在生成新的端口..."
            ja3_port=$(generate_random_port)
        done
        echo "JA3端口: $ja3_port"
    }

    check_port_unique() {
        if [ "$http_port" = "$ja3_port" ]; then
            echo "HTTP端口和JA3端口相同，正在生成新的HTTP端口..."
            http_port=$(generate_random_port)
            check_http_port
        fi
    }

    # 输入或生成HTTP端口
    read -p "请输入HTTP端口（留空自动生成）: " http_port
    http_port=${http_port:-$(generate_random_port)}
    check_http_port

    # 输入或生成JA3端口
    read -p "请输入JA3端口（留空自动生成）: " ja3_port
    ja3_port=${ja3_port:-$(generate_random_port)}
    check_port_unique
    check_ja3_port

    # 输入CLIENTKEY
    read -p "请输入CLIENTKEY: " clientkey
    if [ -z "$clientkey" ]; then
        echo "CLIENTKEY未输入，脚本退出。"
        exit 1
    fi

    # 输入或生成ja3代理服务用户名
    read -p "请输入JA3代理服务用户名（留空自动生成）: " username
    username=${username:-$(generate_random_string 8)}

    # 输入或生成ja3代理服务密码
    read -p "请输入JA3代理服务密码（留空自动生成）: " password
    password=${password:-$(generate_random_string 12)}

    if [ -f docker-compose.yml ]; then
        docker compose down
    fi
    
    # 创建docker-compose.yml文件
cat <<EOF >docker-compose.yml
services:
  ja3-proxy:
    image: xyhelper/ja3-proxy:latest
    ports:
      - "${http_port}:3128" # HTTP端口
      - "${ja3_port}:9988" # JA3端口
    environment:
      WEBSITE_URL: "https://chatgpt.com/?oai-dm=1"
      PROXY: "http://$username:$password@$server_ip:${http_port}"  
      CLIENTKEY: "${clientkey}" 
      LOCALPROXYUSER: "${username}" 
      LOCALPROXYPASS: "${password}" 
EOF

    echo "docker-compose.yml 文件已创建。"

    # 运行docker-compose
    docker compose up -d && echo "ja3proxy: http://$username:$password@$server_ip:${ja3_port}"

    echo "防火墙请打开端口：$http_port 和 $ja3_port"

    echo "http://$username:$password@$server_ip:${ja3_port}" > $proxy_info_file

    echo "Deploying JA3..."
    # Placeholder for the deployment script

    echo "Press Enter to return to menu..."
    read

}

function deployJA3_no_cf() {

    # 获取当前服务器的公网IP
    server_ip=$(curl -s http://checkip.dyndns.org | awk '{print $6}' | cut -d'<' -f1)

    # 检查是否成功获取到服务器的公网IP
    if [ -z "$server_ip" ]; then
        echo "无法获取服务器的公网IP，脚本退出。"
        exit 1
    else
        echo "服务器的公网IP为: $server_ip"
    fi

    # 生成随机端口函数
    generate_random_port() {
        echo $((2000 + RANDOM % 63001))
    }

    # 生成随机字符串函数
    generate_random_string() {
        cat /dev/urandom | tr -dc 'a-z0-9' | fold -w ${1:-16} | head -n 1
    }

    check_ja3_port() {
        while ss -tuln | awk '{print $5}' | grep -q ":$ja3_port$"
        do
            echo "端口$ja3_port已被占用，正在生成新的端口..."
            ja3_port=$(generate_random_port)
        done
        echo "JA3端口: $ja3_port"
    }

    # 输入或生成JA3端口
    read -p "请输入JA3端口（留空自动生成）: " ja3_port
    ja3_port=${ja3_port:-$(generate_random_port)}
    check_ja3_port

    # 输入或生成ja3代理服务用户名
    read -p "请输入JA3代理服务用户名（留空自动生成）: " username
    username=${username:-$(generate_random_string 8)}

    # 输入或生成ja3代理服务密码
    read -p "请输入JA3代理服务密码（留空自动生成）: " password
    password=${password:-$(generate_random_string 12)}

    if [ -f docker-compose.yml ]; then
        docker compose down
    fi
    
    # 创建docker-compose.yml文件
cat <<EOF >docker-compose.yml
services:
  ja3-proxy:
    image: xyhelper/ja3-proxy:latest
    ports:
      - "${ja3_port}:9988" # JA3端口
    environment:
      WEBSITE_URL: "https://chat.openai.com/"
      PROXY: ""  
      CLIENTKEY: "" 
      LOCALPROXYUSER: "${username}" 
      LOCALPROXYPASS: "${password}" 
EOF

    echo "docker-compose.yml 文件已创建。"

    # 运行docker-compose
    docker compose up -d && echo "ja3proxy: http://$username:$password@$server_ip:${ja3_port}"

    echo "防火墙请打开端口：$ja3_port"

    echo "http://$username:$password@$server_ip:${ja3_port}" > $proxy_info_file

    echo "Deploying JA3..."
    # Placeholder for the deployment script

    echo "Press Enter to return to menu..."
    read

}

function viewJA3Proxy() {
    if [ ! -f $proxy_info_file ]; then
        echo "JA3代理信息未找到。请先运行一键部署JA3。"
    else
        proxy_info=$(cat $proxy_info_file)
        echo -e "JA3代理信息: ${GREEN}$proxy_info${PLAIN}"
    fi
    echo "Press Enter to return to menu..."
    read
}

function updateJA3() {
    docker compose pull && docker compose up -d --remove-orphans
    echo "JA3已更新。"
    echo "Press Enter to return to menu..."
    read
}

function main_menu() {
    clear;
    echo -e "${GREEN}** 主菜单 **${PLAIN}"
    echo "1) 检测ChatGPT解锁"
    echo "2) 一键部署JA3-过盾"
    echo "3) 一键部署JA3-无需过盾"
    echo "4) 一键更新JA3" 
    echo "5) 查看JA3Proxy" 
    echo "0) 退出"
    echo -e "${Yellow}请选择一个选项:${PLAIN}"
    read -p "> " action

    case "$action" in
        1) UnlockChatGPTTest;;
        2) deployJA3;;
        3) deployJA3_no_cf;;
        4) updateJA3;;  
        5) viewJA3Proxy;;
        0) exit 0;;
        *) echo -e "${RED}无效的选项，请重新输入。${PLAIN}"
           read
           main_menu;;
    esac
}

# 检查必要的依赖
check_dependencies

# 主循环
while true; do
    main_menu
done
