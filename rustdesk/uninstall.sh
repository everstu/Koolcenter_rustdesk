#!/bin/sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

echo_date "正在删除插件资源文件..."
sh /koolshare/scripts/rustdesk_config.sh stop
rm -rf /koolshare/scripts/rustdesk_config.sh
rm -rf /koolshare/webs/Module_rustdesk.asp
rm -rf /koolshare/res/*rustdesk*
rm -rf /koolshare/configs/rustdesk
find /koolshare/init.d/ -name "*rustdesk*" | xargs rm -rf
rm -rf /koolshare/bin/hbbr >/dev/null 2>&1
rm -rf /koolshare/bin/hbbs >/dev/null 2>&1
rm -rf /koolshare/bin/rustdesk-utils >/dev/null 2>&1
echo_date "插件资源文件删除成功..."

rm -rf /koolshare/scripts/uninstall_rustdesk.sh
echo_date "已成功移除插件... Bye~Bye~"