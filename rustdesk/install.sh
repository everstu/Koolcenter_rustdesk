#!/bin/sh
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=
FW_TYPE_CODE=
FW_TYPE_NAME=
DIR=$(cd $(dirname $0); pwd)
module=${DIR##*/}

get_model(){
	local ODMPID=$(nvram get odmpid)
	local PRODUCTID=$(nvram get productid)
	if [ -n "${ODMPID}" ];then
		MODEL="${ODMPID}"
	else
		MODEL="${PRODUCTID}"
	fi
}

get_fw_type() {
	local KS_TAG=$(nvram get extendno|grep -Eo "kool.+")
	if [ -d "/koolshare" ];then
		if [ -n "${KS_TAG}" ];then
			FW_TYPE_CODE="2"
			FW_TYPE_NAME="${KS_TAG}官改固件"
		else
			FW_TYPE_CODE="4"
			FW_TYPE_NAME="koolshare梅林改版固件"
		fi
	else
		if [ "$(uname -o|grep Merlin)" ];then
			FW_TYPE_CODE="3"
			FW_TYPE_NAME="梅林原版固件"
		else
			FW_TYPE_CODE="1"
			FW_TYPE_NAME="华硕官方固件"
		fi
	fi
}

platform_test(){
	local LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
	local ARCH=$(uname -m)
	if [ -d "/koolshare" -a -f "/usr/bin/skipd" -a "${LINUX_VER}" -ge "41" ];then
		echo_date 机型："${MODEL} ${FW_TYPE_NAME} 符合安装要求，开始安装插件！"
	else
		exit_install 1
	fi
}

set_skin(){
	local UI_TYPE=ASUSWRT
	local SC_SKIN=$(nvram get sc_skin)
	local ROG_FLAG=$(grep -o "680516" /www/form_style.css|head -n1)
	local TUF_FLAG=$(grep -o "D0982C" /www/form_style.css|head -n1)
	local TS_FLAG=$(grep -o "2ED9C3" /www/css/difference.css 2>/dev/null|head -n1)
	if [ -n "${ROG_FLAG}" ];then
		UI_TYPE="ROG"
	fi
	if [ -n "${TUF_FLAG}" ];then
		UI_TYPE="TUF"
	fi
	if [ -n "${TS_FLAG}" ];then
		UI_TYPE="TS"
	fi

	if [ -z "${SC_SKIN}" -o "${SC_SKIN}" != "${UI_TYPE}" ];then
		echo_date "安装${UI_TYPE}皮肤！"
		nvram set sc_skin="${UI_TYPE}"
		nvram commit
	fi
}

exit_install(){
	local state=$1
	case $state in
	1)
		echo_date "本插件适用于【koolshare 梅林改/官改 hnd/axhnd/axhnd.675x】固件平台！"
		echo_date "你的固件平台不能安装！！!"
		echo_date "本插件支持机型/平台：https://github.com/koolshare/rogsoft#rogsoft"
		echo_date "退出安装！"
		rm -rf /tmp/rustdesk* >/dev/null 2>&1
		exit 1
	;;
	0|*)
		rm -rf /tmp/rustdesk* >/dev/null 2>&1
		exit 0
	;;
	esac
}

dbus_nset(){
	# set key when value not exist
	local ret=$(dbus get $1)
	if [ -z "${ret}" ];then
		dbus set $1=$2
	fi
}


install_now() {
	# default value
	local TITLE="RustDesk Server"
	local DESCR="RustDesk是一款优秀的免费开源的远程控制软件，此插件提供RustDesk自建服务器功能。"
	local PLVER=$(cat ${DIR}/version)

	# 生成默认目录
	if [ ! -d /koolshare/configs/rustdesk ];then
	  mkdir -p /koolshare/configs/rustdesk
	fi

	# stop signdog first
	local rustEnable=$(dbus get rustdesk_enable)
	if [ "${rustEnable}" == "1" ];then
		echo_date "先关闭RustDesk插件！以保证更新成功！"
		sh /koolshare/scripts/rustdesk_config.sh stop
		dbus set rustdesk_enable=1
	fi
	
	# remove some files first
	find /koolshare/init.d/ -name "*rustdesk*" | xargs rm -rf

	# isntall file
	echo_date "安装插件相关文件..."
	cp -rf /tmp/${module}/bin/* /koolshare/bin/
	cp -rf /tmp/${module}/res/* /koolshare/res/
	cp -rf /tmp/${module}/scripts/* /koolshare/scripts/
	cp -rf /tmp/${module}/webs/* /koolshare/webs/
	cp -rf /tmp/${module}/uninstall.sh /koolshare/scripts/uninstall_${module}.sh
	mkdir -p /koolshare/configs/rustdesk
	
	#创建开机自启任务
	[ ! -L "/koolshare/init.d/S99rustdesk.sh" ] && ln -sf /koolshare/scripts/rustdesk_config.sh /koolshare/init.d/S99rustdesk.sh
	[ ! -L "/koolshare/init.d/N99rustdesk.sh" ] && ln -sf /koolshare/scripts/rustdesk_config.sh /koolshare/init.d/N99rustdesk.sh

	# Permissions
	chmod +x /koolshare/scripts/* >/dev/null 2>&1
	chmod +x /koolshare/bin/hbbr >/dev/null 2>&1
	chmod +x /koolshare/bin/hbbs >/dev/null 2>&1
	chmod +x /koolshare/bin/rustdesk-utils >/dev/null 2>&1

	# dbus value
	echo_date "设置插件默认参数..."
	dbus set ${module}_version="${PLVER}"
	dbus set softcenter_module_${module}_version="${PLVER}"
	dbus set softcenter_module_${module}_install="1"
	dbus set softcenter_module_${module}_name="${module}"
	dbus set softcenter_module_${module}_title="${TITLE}"
	dbus set softcenter_module_${module}_description="${DESCR}"

	# 获取安装包二进制
	local rustdesk_hbbr_version=$(echo $(/koolshare/bin/hbbr --version) |awk  '{print $2}');
	local rustdesk_hbbs_version=$(echo $(/koolshare/bin/hbbs --version) |awk  '{print $2}');

	# 检查插件默认dbus值
	dbus_nset rustdesk_hbbs_port "21116"
	dbus_nset rustdesk_hbbr_port "21117"
	dbus_nset rustdesk_is_encrypted "0"
	dbus set rustdesk_hbbr_version=$rustdesk_hbbr_version
	dbus set rustdesk_hbbs_version=$rustdesk_hbbs_version

	# 设置证书信息
	rustdesk_key_pub_tmp=$(dbus get rustdesk_key_pub)
	rustdesk_key_priv_tmp=$(dbus get rustdesk_key_priv)
	/koolshare/bin/rustdesk-utils genkeypair |awk '{print $3}' > /tmp/upload/rustdesk_key_cert.tmp
	if [ -z "${rustdesk_key_pub_tmp}" -o -z "${rustdesk_key_priv_tmp}" ];then
		rustdesk_key_pub_tmp=$(cat /tmp/upload/rustdesk_key_cert.tmp |awk 'FNR == 1')
		rustdesk_key_priv_tmp=$(cat /tmp/upload/rustdesk_key_cert.tmp |awk 'FNR == 2')
	fi
	rm -f /tmp/upload/rustdesk_key_cert.tmp >/dev/null 2>&1
	# 写入证书
	echo -n $rustdesk_key_pub_tmp  > /koolshare/configs/rustdesk/id_ed25519.pub
	echo -n $rustdesk_key_priv_tmp  > /koolshare/configs/rustdesk/id_ed25519
	# 设置证书
	dbus set rustdesk_key_pub=$rustdesk_key_pub_tmp
	dbus set rustdesk_key_priv=$rustdesk_key_priv_tmp

	# reenable
	if [ "${rustEnable}" == "1" ];then
		echo_date "重新启动RustDesk插件！"
		sh /koolshare/scripts/rustdesk_config.sh boot_up
	fi

	# finish
	echo_date "${TITLE}插件安装完毕！"
	exit_install
}

install() {
	get_model
	get_fw_type
	platform_test
	install_now
}

install
