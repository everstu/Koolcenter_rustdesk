#!/bin/sh

source /koolshare/scripts/base.sh
eval $(dbus export rustdesk_)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
LOG_FILE=/tmp/upload/rustdesk_log.txt
LOCK_FILE=/var/lock/rustdesk.lock
rustdesk_db_flie_path=/koolshare/configs/rustdesk/
bin_all_run="1"
BASH=${0##*/}
ARGS=$@
connect_key=
hbbsCMD="/koolshare/bin/hbbs"
hbbrCMD="/koolshare/bin/hbbr"
ALWAYS_USE_RELAY="N"
hbbs_used_port=21116

set_lock() {
  exec 233>${LOCK_FILE}
  flock -n 233 || {
    # bring back to original log
    http_response "$ACTION"
    exit 1
  }
}

unset_lock() {
  flock -u 233
  rm -rf ${LOCK_FILE}
}

number_test() {
  case $1 in
  '' | *[!0-9]*)
    echo 1
    ;;
  *)
    echo 0
    ;;
  esac
}

detect_url() {
  local fomart_1=$(echo $1 | grep -E "^https://|^http://")
  local fomart_2=$(echo $1 | grep -E "\.")
  if [ -n "${fomart_1}" -a -n "${fomart_2}" ]; then
    return 0
  else
    return 1
  fi
}

dbus_rm() {
  # remove key when value exist
  if [ -n "$1" ]; then
    dbus remove $1
  fi
}

check_port_used() {
  local port_used=$(netstat -nat | awk -v p1="$hbbs_used_port" -v p2="$hbbs_used_port1" -v p3="$hbbs_used_port2" -v p4="$hbbr_used_port" -v p5="$hbbr_used_port1" '$4 ~ ":"p1"$" || $4 ~ ":"p2"$" || $4 ~ ":"p3"$" || $4 ~ ":"p4"$" || $4 ~ ":"p5"$"' | head -n 1)
  # 最大尝试6次，如果端口还是被占用，就休眠10秒
  local tryTimes=5
  local is_port_used=0
  # 开始休眠并等待端口释放
  until [ ! -n "$port_used" ]; do
    if [ "$tryTimes" -eq  "0" ]; then
      echo_date "ℹ️休眠达最大时间，尝试开启插件..."
      return
    fi
    echo_date "ℹ️检测到端口占用，插件休眠中，剩余尝试次数：$tryTimes"
    sleep 10
    tryTimes=$(($tryTimes - 1))
    is_port_used=1
    port_used=$(netstat -nat | awk -v p1="$hbbs_used_port" -v p2="$hbbs_used_port1" -v p3="$hbbs_used_port2" -v p4="$hbbr_used_port" -v p5="$hbbr_used_port1" '$4 ~ ":"p1"$" || $4 ~ ":"p2"$" || $4 ~ ":"p3"$" || $4 ~ ":"p4"$" || $4 ~ ":"p5"$"' | head -n 1)
  done
  # 端口曾经被占用，现在已经释放
  if [ "$is_port_used" == "1" ]; then
    echo_date "ℹ️端口已释放，开启插件..."
  fi
}

start() {
  # 0. config ENV
  configServerEnv

  # 1. stop first
  stop_process

  # 2. start process
  # 2.1 check_port_used
  check_port_used
  # 2.2 start process
  start_process

  # 3. open port
  close_port >/dev/null 2>&1
  open_port

  echo_date "✅️插件已成功开启！"
}

stop_plugin() {
  # 1. stop process
  stop_process
  # 2.close prot
  close_port >/dev/null 2>&1

  dbus set rustdesk_enable=0

  echo_date "❌️插件已停止运行！"
}

configServerEnv() {
  if [ "$rustdesk_is_encrypted" == "1" ]; then
    connect_key=$rustdesk_key_pub
    hbbsCMD="${hbbsCMD} -k _"
    hbbrCMD="${hbbrCMD} -k _"
  fi

  if [ "$rustdesk_always_use_relay" == "1" ]; then
    ALWAYS_USE_RELAY="Y"
  fi

  if [ $(number_test ${rustdesk_hbbs_port}) != "0" ]; then
    dbus set rustdesk_hbbs_port="21116"
    dbus set rustdesk_hbbr_port="21117"
    rustdesk_hbbs_port=21116
  fi
  hbbs_used_port=$rustdesk_hbbs_port
  hbbs_used_port1=$(($hbbs_used_port - 1))
  hbbs_used_port2=$(($hbbs_used_port + 2))
  hbbr_used_port=$(($hbbs_used_port + 1))
  hbbr_used_port1=$(($hbbr_used_port + 2))
}

start_process() {
  start_hbbs
  start_hbbr
  if [ -z ${bin_all_run} ]; then
    echo_date "❌️进程启动失败，停止插件..."
    stop_plugin
    exit
  fi
}

detect_running_status() {
  local BINNAME=$1
  local PID
  local i=40
  until [ -n "${PID}" ]; do
    usleep 250000
    i=$(($i - 1))
    PID=$(pidof ${BINNAME})
    if [ "$i" -lt 1 ]; then
      echo_date "🔴$1进程启动失败，请检查你的配置！"
      bin_all_run=""
      return
    fi
  done
  echo_date "🟢$1启动成功，pid：${PID}"
}

start_hbbs() {
  HBBS_RUN_LOG=/tmp/upload/rustdesk_hbbs_run_log.txt
  rm -rf ${HBBS_RUN_LOG}
  echo_date "🟠启动 hbbs 进程，开启进程实时守护..."
  mkdir -p /koolshare/perp/hbbs
  cat >/koolshare/perp/hbbs/rc.main <<-EOF
		#!/bin/sh
		source /koolshare/scripts/base.sh
		export DB_URL=${rustdesk_db_flie_path}db_v2.sqlite3
		export PORT=$hbbs_used_port
		export RELAY_SERVERS=$rustdesk_hbbr_host
		export ALWAYS_USE_RELAY=$ALWAYS_USE_RELAY

		CMD="${hbbsCMD}"
		if test \${1} = 'start' ; then
		      cd /koolshare/configs/rustdesk/
		      exec >${HBBS_RUN_LOG} 2>&1
		      exec \$CMD
		fi
		exit 0

	EOF
  chmod +x /koolshare/perp/hbbs/rc.main
  chmod +t /koolshare/perp/hbbs/
  sync
  perpctl A hbbs >/dev/null 2>&1
  perpctl u hbbs >/dev/null 2>&1
  detect_running_status hbbs
}

start_hbbr() {
  HBBR_RUN_LOG=/tmp/upload/rustdesk_hbbr_run_log.txt
  rm -rf ${HBBR_RUN_LOG}
  echo_date "🟠启动 hbbr 进程，开启进程实时守护..."
  mkdir -p /koolshare/perp/hbbr
  cat >/koolshare/perp/hbbr/rc.main <<-EOF
		#!/bin/sh
		source /koolshare/scripts/base.sh
		export PORT=$hbbs_used_port
		#export LIMIT_SPEED=$rustdesk_speed_limit
		#export SINGLE_BANDWIDTH=$rustdesk_hbbr_single_bandwidth
		#export TOTAL_BANDWIDTH=$rustdesk_hbbr_total_bandwidth

		CMD="${hbbrCMD}"
		if test \${1} = 'start' ; then
		  cd /koolshare/configs/rustdesk/
		      exec >${HBBR_RUN_LOG} 2>&1
		      exec \$CMD
		fi
		exit 0

	EOF
  chmod +x /koolshare/perp/hbbr/rc.main
  chmod +t /koolshare/perp/hbbr/
  sync
  perpctl A hbbr >/dev/null 2>&1
  perpctl u hbbr >/dev/null 2>&1
  detect_running_status hbbr
}

stop_process() {
  kill_process "hbbs"
  kill_process "hbbr"
}

kill_process() {
  if [ -f "/koolshare/perp/$1/rc.main" ]; then
    perpctl d $1 >/dev/null 2>&1
  fi
  rm -rf /koolshare/perp/$1 >/dev/null 2>&1

  local PROCESS_PID=$(pidof $1)
  if [ -n "${PROCESS_PID}" ]; then
    echo_date "⛔关闭 $1 进程..."
    killall $1 >/dev/null 2>&1
    kill -9 "${PROCESS_PID}" >/dev/null 2>&1
  fi
}

open_port() {
  local CM=$(lsmod | grep xt_comment)
  local OS=$(uname -r)
  if [ -z "${CM}" -a -f "/lib/modules/${OS}/kernel/net/netfilter/xt_comment.ko" ]; then
    echo_date "ℹ️加载xt_comment.ko内核模块！"
    insmod /lib/modules/${OS}/kernel/net/netfilter/xt_comment.ko
  fi

  local HBBSMATCH=$(iptables -t filter -S INPUT | grep "rustdesk_rule")
  if [ -z "${HBBSMATCH}" ]; then
    echo_date "🧱添加防火墙入站规则..."
    echo_date "🧱打开 RustDesk 服务端口：${hbbs_used_port1} ${hbbs_used_port} ${hbbr_used_port} ${hbbs_used_port2} ${hbbr_used_port1}"
    iptables -I INPUT -p tcp --dport ${hbbs_used_port1} -j ACCEPT -m comment --comment "rustdesk_rule" >/dev/null 2>&1
    iptables -I INPUT -p tcp --dport ${hbbs_used_port} -j ACCEPT -m comment --comment "rustdesk_rule" >/dev/null 2>&1
    iptables -I INPUT -p udp --dport ${hbbs_used_port} -j ACCEPT -m comment --comment "rustdesk_rule" >/dev/null 2>&1
    iptables -I INPUT -p tcp --dport ${hbbs_used_port2} -j ACCEPT -m comment --comment "rustdesk_rule" >/dev/null 2>&1
    iptables -I INPUT -p tcp --dport ${hbbr_used_port} -j ACCEPT -m comment --comment "rustdesk_rule" >/dev/null 2>&1
    iptables -I INPUT -p tcp --dport ${hbbr_used_port1} -j ACCEPT -m comment --comment "rustdesk_rule" >/dev/null 2>&1
  fi
}

close_port() {
  local IPTS=$(iptables -t filter -S | grep "rustdesk_rule" | sed 's/-A/iptables -t filter -D/g')
  if [ -n "${IPTS}" ]; then
    echo_date "🧱关闭本插件在防火墙上打开的所有端口!"
    iptables -t filter -S | grep "rustdesk_rule" | sed 's/-A/iptables -t filter -D/g' >/tmp/rustdesk_clean.sh
    chmod +x /tmp/rustdesk_clean.sh
    sh /tmp/rustdesk_clean.sh >/dev/null 2>&1
    rm /tmp/rustdesk_clean.sh
  fi
}

check_status() {
  local HBBR_PID=$(pidof hbbr)
  local HBBS_PID=$(pidof hbbs)
  local status_text="插件未启用"
  if [ "${rustdesk_enable}" == "1" ]; then
    if [ -n "${HBBS_PID}" ]; then
      status_text="hbbs 进程运行正常！（PID：${HBBS_PID})<br>"
    else
      status_text="hbbs 进程未运行！<br>"
    fi
    if [ -n "${HBBR_PID}" ]; then
      status_text=$status_text"hbbr 进程运行正常！（PID：${HBBR_PID}) "
    else
      status_text=$status_text"hbbr 进程未运行！"
    fi
  fi

  http_response $status_text
}

regenerateKey() {
  echo_date "ℹ️开始重新生成安全密钥对..."
  /koolshare/bin/rustdesk-utils genkeypair | awk '{print $3}' >/tmp/upload/rustdesk_key_cert.tmp
  rustdesk_key_pub_tmp=$(cat /tmp/upload/rustdesk_key_cert.tmp | awk 'FNR == 1')
  rustdesk_key_priv_tmp=$(cat /tmp/upload/rustdesk_key_cert.tmp | awk 'FNR == 2')
  rm -f /tmp/upload/rustdesk_key_cert.tmp >/dev/null 2>&1
  # 写入证书
  echo -n $rustdesk_key_pub_tmp >/koolshare/configs/rustdesk/id_ed25519.pub
  echo -n $rustdesk_key_priv_tmp >/koolshare/configs/rustdesk/id_ed25519
  # 设置证书
  dbus set rustdesk_key_pub=$rustdesk_key_pub_tmp
  dbus set rustdesk_key_priv=$rustdesk_key_priv_tmp
  echo_date "🟢安全密钥对生成成功，即将重新启动插件..."

  start

  echo XU6J03M16 | tee -a /tmp/upload/rustdesk_regenerate_key_log.txt
}

case $1 in
start)
  if [ "${rustdesk_enable}" == "1" ]; then
    sleep 20 #延迟启动等待虚拟内存挂载
    true >${LOG_FILE}
    start | tee -a ${LOG_FILE}
    echo XU6J03M16 >>${LOG_FILE}
    logger "[软件中心-开机自启]: RustDesk Server自启动成功！"
  else
    logger "[软件中心-开机自启]: RustDesk Server未开启，不自动启动！"
  fi
  ;;
boot_up)
  if [ "${rustdesk_enable}" == "1" ]; then
    true >${LOG_FILE}
    start | tee -a ${LOG_FILE}
    echo XU6J03M16 >>${LOG_FILE}
  fi
  ;;
start_nat)
  if [ "${rustdesk_enable}" == "1" ]; then
    logger "[软件中心-NAT重启]: 打开RustDesk Server防火墙端口！"
    sleep 10
    close_port
    sleep 2
    open_port
  fi
  ;;
stop)
  stop_plugin
  ;;
esac

case $2 in
web_submit)
  set_lock
  true >${LOG_FILE}
  http_response "$1"
  if [ "${rustdesk_enable}" == "1" ]; then
    echo_date "▶️开启RustDesk Server！" | tee -a ${LOG_FILE}
    start | tee -a ${LOG_FILE}
  elif [ "${rustdesk_enable}" == "2" ]; then
    echo_date "🔁重启RustDesk Server！" | tee -a ${LOG_FILE}
    dbus set rustdesk_enable=1
    start | tee -a ${LOG_FILE}
  else
    echo_date "ℹ️停止RustDesk Server！" | tee -a ${LOG_FILE}
    stop_plugin | tee -a ${LOG_FILE}
  fi
  echo XU6J03M16 | tee -a ${LOG_FILE}
  unset_lock
  ;;
regenerateKey)
  true >/tmp/upload/rustdesk_regenerate_key_log.txt
  http_response "$1"
  regenerateKey | tee -a /tmp/upload/rustdesk_regenerate_key_log.txt
  ;;
status)
  check_status
  ;;
esac
