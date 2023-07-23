<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Expires" content="-1" />
<link rel="shortcut icon" href="/res/icon-rustdesk.png" />
<link rel="icon" href="/res/icon-rustdesk.png" />
<title>软件中心 - RustDesk Server</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="usp_style.css">
<link rel="stylesheet" type="text/css" href="css/element.css">
<link rel="stylesheet" type="text/css" href="/device-map/device-map.css">
<link rel="stylesheet" type="text/css" href="/js/table/table.css">
<link rel="stylesheet" type="text/css" href="/res/layer/theme/default/layer.css">
<link rel="stylesheet" type="text/css" href="/res/softcenter.css">
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" language="JavaScript" src="/js/table/table.js"></script>
<script type="text/javascript" language="JavaScript" src="/client_function.js"></script>
<script type="text/javascript" src="/res/softcenter.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
<script type="text/javascript" src="/validator.js"></script>
<style>
a:focus {
	outline: none;
}
.SimpleNote {
	padding:5px 5px;
}
i {
    color: #FC0;
    font-style: normal;
}
.loadingBarBlock{
	width:740px;
}
.popup_bar_bg_ks{
	position:fixed;
	margin: auto;
	top: 0;
	left: 0;
	width:100%;
	height:100%;
	z-index:99;
	/*background-color: #444F53;*/
	filter:alpha(opacity=90);  /*IE5、IE5.5、IE6、IE7*/
	background-repeat: repeat;
	visibility:hidden;
	overflow:hidden;
	/*background: url(/images/New_ui/login_bg.png);*/
	background:rgba(68, 79, 83, 0.85) none repeat scroll 0 0 !important;
	background-position: 0 0;
	background-size: cover;
	opacity: .94;
}

.FormTitle em {
    color: #00ffe4;
    font-style: normal;
    /*font-weight:bold;*/
}
.FormTable th {
	width: 30%;
}
.formfonttitle {
	font-family: Roboto-Light, "Microsoft JhengHei";
	font-size: 18px;
	margin-left: 5px;
}
.FormTitle, .FormTable, .FormTable th, .FormTable td, .FormTable thead td, .FormTable_table, .FormTable_table th, .FormTable_table td, .FormTable_table thead td {
	font-size: 14px;
	font-family: Roboto-Light, "Microsoft JhengHei";
}
</style>
<script type="text/javascript">
var dbus = {};
var refresh_flag
var db_rustdesk = {}
var count_down;
var _responseLen;
var STATUS_FLAG;
var noChange = 0;
var params_check = ['rustdesk_is_encrypted','rustdesk_always_use_relay'];
var params_input = ['rustdesk_hbbr_port', 'rustdesk_hbbs_port', 'rustdesk_hbbr_host','rustdesk_key_pub'];

String.prototype.myReplace = function(f, e){
	var reg = new RegExp(f, "g");
	return this.replace(reg, e);
}

function init() {
	show_menu(menu_hook);
	register_event();
	get_dbus_data();
	check_status();
}

function get_dbus_data(){
	$.ajax({
		type: "GET",
		url: "/_api/rustdesk_",
		dataType: "json",
		async: false,
		success: function(data) {
			dbus = data.result[0];
			conf2obj();
			show_hide_element();
		}
	});
}


function conf2obj(){
	for (var i = 0; i < params_check.length; i++) {
		if(dbus[params_check[i]]){
			E(params_check[i]).checked = dbus[params_check[i]] != "0";
		}
	}
	for (var i = 0; i < params_input.length; i++) {
		if (dbus[params_input[i]]) {
			$("#" + params_input[i]).val(dbus[params_input[i]]);
		}
	}
	if (dbus["rustdesk_version"]){
		E("rustdesk_version").innerHTML = " - " + dbus["rustdesk_version"];
	}

	if (dbus["rustdesk_hbbs_version"]){
		E("rustdesk_hbbs_version").innerHTML = "hbbs程序版本：<em>" + dbus["rustdesk_hbbs_version"] + "</em>";
	}else{
		E("rustdesk_hbbs_version").innerHTML = "hbbs程序版本：<em>null</em>";
	}

	if (dbus["rustdesk_hbbr_version"]){
		E("rustdesk_hbbr_version").innerHTML = "hbbr程序版本：<em>" + dbus["rustdesk_hbbr_version"] + "</em>";
	}else{
		E("rustdesk_hbbr_version").innerHTML = "hbbr程序版本：<em>null</em>";
	}
}

function show_hide_element(){
	if(dbus["rustdesk_enable"] == "1"){
		E("rustdesk_status_tr").style.display = "";
		E("rustdesk_version_tr").style.display = "";
		E("rustdesk_info_tr").style.display = "";
		E("rustdesk_apply_btn_1").style.display = "none";
		E("rustdesk_apply_btn_2").style.display = "";
		E("rustdesk_apply_btn_3").style.display = "";
	}else{
		E("rustdesk_status_tr").style.display = "";
		E("rustdesk_version_tr").style.display = "";
		E("rustdesk_info_tr").style.display = "none";
		E("rustdesk_apply_btn_1").style.display = "";
		E("rustdesk_apply_btn_2").style.display = "none";
		E("rustdesk_apply_btn_3").style.display = "none";
	}
}

function menu_hook(title, tab) {
	tabtitle[tabtitle.length - 1] = new Array("", "RustDesk Server");
	tablink[tablink.length - 1] = new Array("", "Module_rustdesk.asp");
}

function register_event(){
	$(".popup_bar_bg_ks").click(
		function() {
			count_down = -1;
		});
	$(window).resize(function(){
		var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
		var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
		if($('.popup_bar_bg_ks').css("visibility") == "visible"){
			document.scrollingElement.scrollTop = 0;
			var log_h = E("loadingBarBlock").clientHeight;
			var log_w = E("loadingBarBlock").clientWidth;
			var log_h_offset = (page_h - log_h) / 2;
			var log_w_offset = (page_w - log_w) / 2 + 90;
			$('#loadingBarBlock').offset({top: log_h_offset, left: log_w_offset});
		}
	});
}

function check_status(){
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "rustdesk_config.sh", "params":['status'], "fields": ""};
	$.ajax({
		type: "POST",
		url: "/_api/",
		async: true,
		data: JSON.stringify(postData),
		success: function (response) {
			E("rustdesk_status").innerHTML = response.result;
			setTimeout("check_status();", 10000);
		},
		error: function(){
			E("rustdesk_status").innerHTML = "获取运行状态失败";
			setTimeout("check_status();", 5000);
		}
	});
}

function save(flag){
	var db_rustdesk = {};
	if(flag){
		db_rustdesk["rustdesk_enable"] = flag;
	}else{
		db_rustdesk["rustdesk_enable"] = "0";
	}
	for (var i = 0; i < params_check.length; i++) {
			db_rustdesk[params_check[i]] = E(params_check[i]).checked ? '1' : '0';
	}
	for (var i = 0; i < params_input.length; i++) {
		if (E(params_input[i])) {
			db_rustdesk[params_input[i]] = E(params_input[i]).value;
		}
	}
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "rustdesk_config.sh", "params": ["web_submit"], "fields": db_rustdesk};
	$.ajax({
		type: "POST",
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			if(response.result == id){
				get_log();
			}
		}
	});
}

function get_log(flag, path){
    var url = "/_temp/rustdesk_log.txt";
    if(path){
        url = path;
    }
    console.log(path);
	E("ok_button").style.visibility = "hidden";
	showALLoadingBar();
	$.ajax({
		url: url,
		type: 'GET',
		cache:false,
		dataType: 'text',
		success: function(response) {
			var retArea = E("log_content");
			if (response.search("XU6J03M16") != -1) {
				retArea.value = response.myReplace("XU6J03M16", " ");
				E("ok_button").style.visibility = "visible";
				retArea.scrollTop = retArea.scrollHeight;
				if(flag == 1){
					count_down = -1;
					refresh_flag = 0;
				}else{
					count_down = 6;
					refresh_flag = 1;
				}
				count_down_close();
				return false;
			}
			setTimeout(`get_log(${flag},"${url}")`, 500);
			retArea.value = response.myReplace("XU6J03M16", " ");
			retArea.scrollTop = retArea.scrollHeight;
		},
		error: function(xhr) {
			E("loading_block_title").innerHTML = "暂无日志信息 ...";
			E("log_content").value = "日志文件为空，请关闭本窗口！";
			E("ok_button").style.visibility = "visible";
			return false;
		}
	});
}

function showALLoadingBar(){
	document.scrollingElement.scrollTop = 0;
	E("loading_block_title").innerHTML = "&nbsp;&nbsp;rustdesk日志信息";
	E("LoadingBar").style.visibility = "visible";
	var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
	var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
	var log_h = E("loadingBarBlock").clientHeight;
	var log_w = E("loadingBarBlock").clientWidth;
	var log_h_offset = (page_h - log_h) / 2;
	var log_w_offset = (page_w - log_w) / 2 + 90;
	$('#loadingBarBlock').offset({top: log_h_offset, left: log_w_offset});
}
function hideALLoadingBar(){
	E("LoadingBar").style.visibility = "hidden";
	E("ok_button").style.visibility = "hidden";
	if (refresh_flag == "1"){
		refreshpage();
	}
}
function count_down_close() {
	if (count_down == "0") {
		hideALLoadingBar();
	}
	if (count_down < 0) {
		E("ok_button1").value = "手动关闭"
		return false;
	}
	E("ok_button1").value = "自动关闭（" + count_down + "）"
		--count_down;
	setTimeout("count_down_close();", 1000);
}

function close() {
	if (confirm('确定马上关闭吗.?')) {
		showLoading(2);
		refreshpage(2);
		var id = parseInt(Math.random() * 100000000);
		var postData = { "id": id, "method": "rustdesk_config.sh", "params": ["stop"], "fields": "" };
		$.ajax({
			url: "/_api/",
			cache: false,
			type: "POST",
			dataType: "json",
			data: JSON.stringify(postData)
		});
	}
}

var runLogInterval;
function get_run_log(type){
	if(STATUS_FLAG == 0) return;
	var url= '/_temp/rustdesk_hbbr_run_log.txt';
	if(type == 1){
		url= '/_temp/rustdesk_hbbs_run_log.txt';
	}
	$.ajax({
		url: url,
		type: 'GET',
		dataType: 'html',
		async: true,
		cache: false,
		success: function(response) {
			var retArea = E("log_content_rustdesk");
			if (_responseLen == response.length) {
				noChange++;
			} else {
				noChange = 0;
			}
			if (noChange > 10) {
				return false;
			} else {
			    if(! runLogInterval){
			        runLogInterval = setInterval(()=>{
			            get_run_log(type)
			        },1500);
			    }
			}
			retArea.value = response;

			if(E("rustdesk_stop_log").checked == false){
				retArea.scrollTop = retArea.scrollHeight;
			}
			_responseLen = response.length;
		},
		error: function(xhr) {
			E("log_pannel_title").innerHTML = "暂无日志信息 ...";
			E("log_content_rustdesk").value = "日志文件为空，请关闭本窗口！";
			setTimeout(`get_run_log(${type})`, 5000);
		}
	});
}

function show_log_pannel(type){
	document.scrollingElement.scrollTop = 0;
	E("log_pannel_div").style.visibility = "visible";
	var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
	var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
	var log_h = E("log_pannel_table").clientHeight;
	var log_w = E("log_pannel_table").clientWidth;
	var log_h_offset = (page_h - log_h) / 2;
	var log_w_offset = (page_w - log_w) / 2;
	$('#log_pannel_table').offset({top: log_h_offset, left: log_w_offset});
	STATUS_FLAG = 1;
	get_run_log(type);
}

function hide_log_pannel(){
	E("log_pannel_div").style.visibility = "hidden";
	STATUS_FLAG = 0;
	clearInterval(runLogInterval);
	runLogInterval=null;
}

function regenerateKey(){
    require(['/res/layer/layer.js'], function(layer) {
        layer.confirm('确定要重新生成加密访问使用的密钥对吗？', {
        	shade: 0.8,icon: 3, title:'重新生成密钥对'
        }, function(index) {
        	var id = parseInt(Math.random() * 100000000);
        	var postData = {"id": id, "method": "rustdesk_config.sh", "params": ["regenerateKey"], "fields": []};
        	console.log(postData);
        	$.ajax({
        		type: "POST",
        		url: "/_api/",
        		data: JSON.stringify(postData),
        		dataType: "json",
        		success: function(response) {
        			if(response.result == id){
        				get_log(0,"/_temp/rustdesk_regenerate_key_log.txt");
        			}
        		}
        	});
        	layer.close(index);
        	return true;
        }, function(index) {
        	layer.close(index);
        	return false;
        });
    });
}

function open_rustdesk_hint(itemNum) {
	statusmenu = "";
	width = "350px";
	if (itemNum == 1) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;1. 此处显示RustDesk Server二进制程序在路由器后台的简要运行情况，详细运行日志可以点击顶部的<b>Rustdesk运行日志</b>查看。<br/><br/>"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;3. 当出现<b>获取运行状态失败</b>时，可能是路由器后台登陆超时或者httpd进程崩溃导致，如果是后者，请等待路由器httpd进程恢复，或者自行使用ssh命令：server restart_httpd重启httpd。<br/><br/>"
		_caption = "运行状态";
	}
	if (itemNum == 2) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;1. 此处显示RustDesk Server二进制程序的hbbs版本号及其hbbr版本号。<br/><br/>"
		_caption = "运行状态";
	}
	if (itemNum == 3) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;点击【rustdesk运行日志】可以实时查看rustdesk中继服务器程序的运行情况。<br/><br/>"
		_caption = "信息获取";
	}
	if (itemNum == 4) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;仅允许加密访问<br/><br/>"
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;开启此选项您将禁止没有key的用户建立非加密连接<br/><br/>"
		_caption = "加密访问";
	}
	if (itemNum == 5) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;此处展示加密访问使用的key。<br/><br/>"
		_caption = "加密访问";
	}
	if (itemNum == 6) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;此处允许自定义hbbs的端口，hbbs服务是用于ID服务。<br/><br/>"
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;默认端口为：21116，自动推断：21115/21118端口<br/><br/>"
		_caption = "hbbs端口";
	}
	if (itemNum == 7) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;此处展示hbbr的端口，hbbr服务是用于中继服务。<br/><br/>"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;由于相关服务会自动推断端口，故只需填写hbbs端口，其他端口自动推断。<br/><br/>"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;默认端口：21117，自动推断：21119<br/><br/>"
		_caption = "hbbs端口";
	}
	if (itemNum == 8) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;hbbr中继服务器地址<br/><br/>"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;如果填写则配置客户端的时候不用填写中继服务器地址，hbbs服务会自动转发到中继服务器。<br/><br/>"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;如果未使用默认端口则需要填写hbbr服务端口。<br/><br/>"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;示例1：rustdesk.example.com<br/><br/>"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;示例2：rustdesk.example.com:11115<br/><br/>"
		_caption = "中继服务器地址";
	}
	if (itemNum == 9) {
		statusmenu = "&nbsp;&nbsp;&nbsp;&nbsp;强制使用中继服务器<br/><br/>"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;强制使用中继服务器可减少链接等待时间。<br/><br/>"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;默认rustdesk会优先使用打洞连接双方机器，但打洞可能会耗费更多时间去尝试。<br/><br/>"
		statusmenu += "&nbsp;&nbsp;&nbsp;&nbsp;强制使用中继服务器能减少设备连接时间，但同时可能对带宽要求较高，请慎重开启！！<br/><br/>"
		_caption = "强制使用中继服务器";
	}

	return overlib(statusmenu, OFFSETX, 10, OFFSETY, 10, RIGHT, STICKY, WIDTH, 'width', CAPTION, _caption, CLOSETITLE, '');

	var tag_name = document.getElementsByTagName('a');
	for (var i = 0; i < tag_name.length; i++)
		tag_name[i].onmouseout = nd;

	if (helpcontent == [] || helpcontent == "" || hint_array_id > helpcontent.length)
		return overlib('<#defaultHint#>', HAUTO, VAUTO);
	else if (hint_array_id == 0 && hint_show_id > 21 && hint_show_id < 24)
		return overlib(helpcontent[hint_array_id][hint_show_id], FIXX, 270, FIXY, 30);
	else {
		if (hint_show_id > helpcontent[hint_array_id].length)
			return overlib('<#defaultHint#>', HAUTO, VAUTO);
		else
			return overlib(helpcontent[hint_array_id][hint_show_id], HAUTO, VAUTO);
	}
}
function mOver(obj, hint){
	$(obj).css({
		"color": "#00ffe4",
		"text-decoration": "underline"
	});
	open_rustdesk_hint(hint);
}
function mOut(obj){
	$(obj).css({
		"color": "#fff",
		"text-decoration": ""
	});
	E("overDiv").style.visibility = "hidden";
}

function guessHbbrPort(obj){
    var obj = $(obj);
    var port = obj.val();
    var reg = /^\d{4,5}$/;
    if(! reg.test(port)){
        port = 21116;
        obj.val(port);
    }
    $('#rustdesk_hbbr_port').val(parseInt(port) +1);
}

function cpoyText(obj){
    obj.select();
    const successful = document.execCommand('copy');
    require(['/res/layer/layer.js'], function(layer) {
        if(successful){
        	layer.msg("复制成功",{icon: 6});
        }else{
        	layer.msg("复制失败",{icon: 5});
        }
    });
}
</script>
</head>
<body id="app" skin='<% nvram_get("sc_skin"); %>' onload="init();">
	<div id="TopBanner"></div>
	<div id="Loading" class="popup_bg"></div>
	<div id="LoadingBar" class="popup_bar_bg_ks" style="z-index: 200;" >
		<table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock" align="center">
			<tr>
				<td height="100">
					<div id="loading_block_title" style="margin:10px auto;margin-left:10px;width:85%; font-size:12pt;"></div>
					<div id="loading_block_spilt" style="margin:10px 0 10px 5px;" class="loading_block_spilt">
						<li><font color="#ffcc00">请等待日志显示完毕，并出现自动关闭按钮！</font></li>
						<li><font color="#ffcc00">在此期间请不要刷新本页面，不然可能导致问题！</font></li>
					</div>
					<div style="margin-left:15px;margin-right:15px;margin-top:10px;outline: 1px solid #3c3c3c;overflow:hidden">
						<textarea cols="50" rows="25" wrap="off" readonly="readonly" id="log_content" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="white-space:break-spaces;border:1px solid #000;width:99%; font-family:'Lucida Console'; font-size:11px;background:transparent;color:#FFFFFF;outline: none;padding-left:5px;padding-right:22px;overflow-x:hidden"></textarea>
					</div>
					<div id="ok_button" class="apply_gen" style="background:#000;visibility:hidden;">
						<input id="ok_button1" class="button_gen" type="button" onclick="hideALLoadingBar()" value="确定">
					</div>
				</td>
			</tr>
		</table>
	</div>
	<div id="log_pannel_div" class="popup_bar_bg_ks" style="z-index: 200;" >
		<table cellpadding="5" cellspacing="0" id="log_pannel_table" class="loadingBarBlock" style="width:960px" align="center">
			<tr>
				<td height="100">
					<div style="text-align: center;font-size: 18px;color: #99FF00;padding: 10px;font-weight: bold;">RustDesk服务器日志信息</div>
					<div style="margin-left:15px"><i>🗒️此处展示RustDesk服务器的运行日志...</i></div>
					<div style="margin-left:15px;margin-right:15px;margin-top:10px;outline: 1px solid #3c3c3c;overflow:hidden">
						<textarea cols="50" rows="32" wrap="off" readonly="readonly" id="log_content_rustdesk" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="white-space:break-spaces;border:1px solid #000;width:99%; font-family:'Lucida Console'; font-size:11px;background:transparent;color:#FFFFFF;outline: none;padding-left:5px;padding-right:22px;line-height:1.3;overflow-x:hidden"></textarea>
					</div>
					<div id="ok_button_rustdesk" class="apply_gen" style="background:#000;">
						<input class="button_gen" type="button" onclick="hide_log_pannel()" value="返回主界面">
						<input style="margin-left:10px" type="checkbox" id="rustdesk_stop_log">
						<lable>&nbsp;暂停日志刷新</lable>
					</div>
				</td>
			</tr>
		</table>
	</div>
	<iframe name="hidden_frame" id="hidden_frame" width="0" height="0" frameborder="0"></iframe>
	<!--=============================================================================================================-->
	<table class="content" align="center" cellpadding="0" cellspacing="0">
		<tr>
			<td width="17">&nbsp;</td>
			<td valign="top" width="202">
				<div id="mainMenu"></div>
				<div id="subMenu"></div>
			</td>
			<td valign="top">
				<div id="tabMenu" class="submenuBlock"></div>
				<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
					<tr>
						<td align="left" valign="top">
							<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
								<tr>
									<td bgcolor="#4D595D" colspan="3" valign="top">
										<div>&nbsp;</div>
										<div class="formfonttitle">RustDesk Server<lable id="rustdesk_version"></lable></div>
										<div style="float: right; width: 15px; height: 25px; margin-top: -20px">
											<img id="return_btn" alt="" onclick="reload_Soft_Center();" align="right" style="cursor: pointer; position: absolute; margin-left: -30px; margin-top: -25px;" title="返回软件中心" src="/images/backprev.png" onmouseover="this.src='/images/backprevclick.png'" onmouseout="this.src='/images/backprev.png'" />
										</div>
										<div style="margin: 10px 0 10px 5px;" class="splitLine"></div>
										<div class="SimpleNote">
											<a href="https://github.com/rustdesk/rustdesk" target="_blank"><em><u>RustDesk</u></em></a>是一款优秀的免费开源的远程控制软件，此插件提供<a href="https://github.com/rustdesk/rustdesk-server" target="_blank"><em><u>RustDesk Server</u></em></a>自建功能。
											<span><a type="button" href="https://github.com/everstu/Koolcenter_rustdesk/blob/master/Changelog.txt" target="_blank" class="ks_btn" style="margin-left:5px;" >更新日志</a></span>
											<span><a type="button" class="ks_btn" href="javascript:void(0);" onclick="get_log(1)" style="margin-left:5px;">插件日志</a></span>
										</div>
										<div id="rustdesk_status_pannel">
											<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<thead>
													<tr>
														<td colspan="2">RustDesk Server - 状态</td>
													</tr>
												</thead>
												<tr id="rustdesk_status_tr" style="display: none;">
													<th><a onmouseover="mOver(this, 1)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">运行状态</a></th>
													<td>
														<span id="rustdesk_status">Waiting...</span>
													</td>
												</tr>
												<tr id="rustdesk_version_tr" style="display: none;">
													<th><a onmouseover="mOver(this, 2)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">版本信息</a></th>
													<td>
														<span id="rustdesk_hbbs_version"></span><br>
														<span id="rustdesk_hbbr_version"></span>
													</td>
												</tr>
												<tr id="rustdesk_info_tr" style="display: none;">
													<th><a onmouseover="mOver(this, 3)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">信息获取</a></th>
													<td>
														<a type="button" class="ks_btn" href="javascript:void(0);" onclick="show_log_pannel(1)" >hbbs运行日志</a>
														<a type="button" class="ks_btn" href="javascript:void(0);" onclick="show_log_pannel(2)" >hbbr运行日志</a>
													</td>
												</tr>
											</table>
										</div>
										<div id="rustdesk_setting_pannel" style="margin-top:10px">
											<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<thead>
													<tr>
														<td colspan="2">RustDesk Server - 设置</td>
													</tr>
												</thead>
												<tr>
													<th><a onmouseover="mOver(this, 4)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">仅允许加密访问</a></th>
													<td>
														<input type="checkbox" id="rustdesk_is_encrypted" style="vertical-align:middle;">
													</td>
												</tr>
												<tr>
													<th><a onmouseover="mOver(this, 9)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">强制使用中继服务器</a></th>
													<td>
														<input type="checkbox" id="rustdesk_always_use_relay" style="vertical-align:middle;">
													</td>
												</tr>
												<tr id="rustdesk_cert_key_tr">
													<th><a onmouseover="mOver(this, 5)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">加密访问Key<lable id="warn_cdn" style="color:red;margin-left:5px"><lable></a></th>
													<td>
													<input type="text" id="rustdesk_key_pub" style="width: 75%;" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="" readonly onclick="cpoyText(this);" title="点击文本框复制KEY">
														<a type="button" class="ks_btn" href="javascript:void(0);" onclick="regenerateKey()" style="margin-left:5px;">重新生成</a>
													</td>
												</tr>
												<tr id="rustdesk_hbbs_port_tr">
													<th><a onmouseover="mOver(this, 6)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">hbbs服务端口</a></th>
													<td>
														<input type="text" id="rustdesk_hbbs_port" style="width: 50px;" maxlength="5" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="21116" onblur="guessHbbrPort(this);">
													</td>
												</tr>
												<tr id="rustdesk_hbbr_port_tr">
													<th><a onmouseover="mOver(this, 7)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">hbbr服务端口</a></th>
													<td>
														<input type="text" id="rustdesk_hbbr_port" style="width: 50px;" maxlength="5" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="21117" readonly>
													</td>
												</tr>
												<tr id="rustdesk_hbbr_host_tr">
													<th><a onmouseover="mOver(this, 8)" onmouseout="mOut(this)" class="hintstyle" href="javascript:void(0);">hbbr服务host<br></a></th>
													<td>
													<input type="text" id="rustdesk_hbbr_host" style="width: 95%;" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="">
													</td>
												</tr>
											</table>
										</div>
										<div id="rustdesk_apply" class="apply_gen">
											<input class="button_gen" style="display: none;" id="rustdesk_apply_btn_1" onClick="save(1)" type="button" value="开启" />
											<input class="button_gen" style="display: none;" id="rustdesk_apply_btn_2" onClick="save(2)" type="button" value="重启" />
											<input class="button_gen" style="display: none;" id="rustdesk_apply_btn_3" onClick="save(0)" type="button" value="关闭" />
										</div>
										<div style="margin: 10px 0 10px 5px;" class="splitLine"></div>
										<div style="margin:10px 0 0 5px">
											<li>RustDesk客户端下载地址，全平台支持！<a href="https://rustdesk.com/" target="_blank"><em>点这里前往下载</em></a></li>
											<li>如有不懂，特别是RustDesk Server配置文件的填写，请查看RustDesk官方文档<a href="https://rustdesk.com/docs/zh-cn/self-host/" target="_blank"><em>点这里看文档</em></a></li>
											<li>插件使用有任何问题请加入<a href="https://t.me/xbchat" target="_blank"><em><u>koolcenter TG群</u></em></a>或<a href="https://t.me/meilinchajian" target="_blank"><em><u>Mc Chat TG群</u></em></a>联系 @fiswonder<br></li>
										</div>
									</td>
								</tr>
							</table>
						</td>
					</tr>
				</table>
			</td>
			<td width="10" align="center" valign="top"></td>
		</tr>
	</table>
	<div id="footer"></div>
</body>
</html>

