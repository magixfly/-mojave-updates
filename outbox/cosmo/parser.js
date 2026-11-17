var apptype = -1;
var prev_apptype = -1;
var camera_connected = 0;

var automovement_values = {
	pan: 0.0,
	tilt: 0.0,
	roll: 0.0,
	zoom: 1.0,
	ev: 0.0,
	afx: 0.5,
	afy: 0.5,
	mf: -1
}


String.prototype.replaceAll = function (stringToFind, stringToReplace) {
        if (stringToFind === stringToReplace) return this;
        var temp = this;
        var index = temp.indexOf(stringToFind);
        while (index != -1) {
            temp = temp.replace(stringToFind, stringToReplace);
            index = temp.indexOf(stringToFind);
        }
        return temp;
    };



function parseTelemetry(event) {

	var buf = new Uint8Array(event.data); 

	switch (buf[0]) {

		case 123: /// '{'
			//console.log(bin2String(buf));
			var str = bin2String(buf);
			str = str.replace(',}', '}');
			str = str.replaceAll("\n", '<br>');
			str = str.replaceAll("\r", '');
			str = str.replaceAll("\t", '');
			try { ParseDeviceConfig(str); } catch (e) {}
			return;
		break;

		case PACKET_ID.PACKET_SERVER_STATUS:

			apptype = buf[1] & 0x7F;
			var apptypestr = app_types_array[apptype];
			var licenseok = buf[2] & 1;
			var gimballicenseok = (buf[2] >> 2) & 1;
			var boardsupported = (buf[2] >> 1) & 1;
			var clientcount = buf[3];
			var wlanstatus = buf[4];
			var datavideoactive = buf[5];
			var restreamactive = buf[6];
			var restreamactive2 = 0;
			try { restreamactive2 = buf[51]; } catch (e) { }
			var rtmptime = buf[7] + (buf[8] << 8) + (buf[9] << 16) + (buf[10] << 24);
			var rtmptime2 = 0;
			try { rtmptime2 = buf[58] + (buf[59] << 8) + (buf[60] << 16) + (buf[61] << 24); } catch (e) {}
			var rtsptime = buf[31] + (buf[32] << 8) + (buf[33] << 16) + (buf[34] << 24);
			var srttime = 0;
			try { srttime = buf[27] + (buf[28] << 8) + (buf[29] << 16) + (buf[30] << 24); } catch (e) {}
			var onboardrectime = buf[11] + (buf[12] << 8) + (buf[13] << 16) + (buf[14] << 24);
			var rc1state = buf[15];
			var rc2state = buf[16];
			var osd_enabled = buf[17] & 1;
			var osd_borders = (buf[17] >> 1) & 1;
			var temperature = buf[18];
			var app_minor = buf[19];
			var app_major = buf[20];
			var app_build = buf[21];

			var rec_storage = buf[22];
			var rec_storage_freespace = buf[23] + (buf[24] << 8) + (buf[25] << 16) + (buf[26] << 24);

			var app_version_str = "v. " + app_minor + "." + app_major + "." + app_build;
			var ap_active = (wlanstatus & 1) == 1;
			var wlan_active = ((wlanstatus >> 1) & 1) == 1;
			var cam_active = ((wlanstatus >> 2) & 1) == 1;

			var servocontrol_enabled = false;
			var servocontrol_joystick_type = 0;
			var servocontrol_active_channels_bits = 0;
			try {
				servocontrol_enabled = buf[41] == 1;
				servocontrol_joystick_type = buf[42];
				servocontrol_active_channels_bits = buf[43];
				servocontrol_values = [];
				servocontrol_values[0] = buf[54];
				servocontrol_values[1] = buf[55];
				servocontrol_values[2] = buf[56];
				servocontrol_values[3] = buf[57];
				ServoControlsParse(servocontrol_enabled, servocontrol_active_channels_bits, servocontrol_joystick_type, servocontrol_values);
			} catch (e) {}

			var health = 0;
			try { 
				health = buf[50];

                var health_msg = "";
                if (((health >> 0) & 1) == 1) health_msg += "under-voltage";
                if (((health >> 1) & 1) == 1) health_msg += ", currently throttled";
                if (((health >> 2) & 1) == 1) health_msg += ", arm frequency capped";
                if (((health >> 3) & 1) == 1) health_msg += ", soft temperature reached";

				if (health == 0) {
					$("#health_msg").css('color','yellow');
					$("#health_msg").html('Ok');
					$("#health_msg").attr('title', '');
				} else {
					$("#health_msg").css('color','red');
					$("#health_msg").html('Health bad');
					$("#health_msg").attr('title', health_msg);
				}

				$("#health_msg").css('display','inline');

			} catch (e) {
				$("#health_msg").css('display','none');
			}


			var audio_available = 0;
			try {
				audio_available = buf[52] & 0x1;
				if (audio_available) {
					$("#audio_icons_area").css('display', 'inline');
				} else {
					$("#audio_icons_area").css('display', 'none');
				}
			} catch (e) {}

			var cpu_load = 0;
			try {
				cpu_load = buf[53];
				$("#cpu_load").text(cpu_load + '%');
				$("#cpu_load").css('display', 'inline');
			} catch (e) {}

			try {
				if (HookOnboardRecording != undefined) HookOnboardRecording(parseInt(onboardrectime), parseInt(rec_storage), parseInt(rec_storage_freespace));
			} catch {}


			camera_connected = datavideoactive;

			/// If app type was changed
			if (apptype != prev_apptype) {
				prev_apptype = apptype;
				onAppTypeChanged(apptype);
			}


			/// Draw elements

			try {
				/// For Electron.js
				document.title = apptypestr + " " + app_version_str + " - " + currentDevice.host;
			} catch (e) {
				document.title = apptypestr + " " + app_version_str + " - " + window.IP;
			}


			if (!boardsupported) {
				$("#boardsupported_block").css("display","block");
			} else {
				$("#boardsupported_block").css("display","none");
			}

			if (!licenseok) {
				$("#license_block").css("display","block");
				$("#license_block").html("Bad license Cosmostreamer NG " + apptypestr + " " + app_version_str);
				$("#qr_block").css("display","block");
			} else {
				$("#license_block").css("display","none");
				$("#license_block").html();
				$("#qr_block").css("display","none");
			}

			if (!gimballicenseok) {
				$("#gimbal_license_key_bad_message").css("display", "block");
			} else {
				$("#gimbal_license_key_bad_message").css("display", "none");
			}

			if (datavideoactive) {
				//$("#top_area").css('display','block');
				//$("#bottom_area").css('display','block');
				//$("#top_area").html("&nbsp;");
				//$("#bottom_area").html("&nbsp;");

				$("#cameradisconnectedmessage").css('display','none');
			} else {
				//$("#top_area").css('display','none');
				//$("#bottom_area").css('display','none');
				$("#top_area").html("&nbsp;");
				$("#bottom_area").html("&nbsp;");

				$("#cameradisconnectedmessage").css('display','block');

				$(".needhide").css('display','none');
			}


			$("#app_type").html(apptypestr);
			$("#clients_count").html("Clients: " + clientcount);
			$("#cpu_temp").html(temperature + "&deg;C");


			if (cam_active) {
				$("#camstatus").css('display', 'inline');
			} else {
				$("#camstatus").css('display', 'none');
			}
			if (wlan_active) {
				$("#wlanstatus").css('display', 'inline');
			} else {
				$("#wlanstatus").css('display', 'none');
			}
			if (ap_active) {
				$("#apstatus").css('display', 'inline');
			} else {
				$("#apstatus").css('display', 'none');
			}


			$("#rc1status").css("display", rc1state > 0 ? "inline" : "none");
			$("#rc2status").css("display", rc2state > 0 ? "inline" : "none");

			$("#rc1status").html("RC1 " + rc_state_array[rc1state]);
			$("#rc2status").html("RC2 " + rc_state_array[rc2state]);

			/// Cal RC update state for RC config settings tab
			try { SettingsRCUpdateStatus(rc1state, rc2state) } catch (e) { }


			/// Restreaming

			var onboard_rec = (restreamactive >> 0) & 1 == 1;
			var udp_restream = (restreamactive >> 1) & 1 == 1;
			var rtmp_restream = (restreamactive >> 2) & 1 == 1;
			var srt_restream = (restreamactive >> 3) & 1 == 1;
			var rtsp_restream = (restreamactive >> 4) & 1 == 1;
			var rtp_restream = (restreamactive >> 5) & 1 == 1;
			var ndi_restream = (restreamactive >> 6) & 1 == 1;
			var v4l2_restream = (restreamactive >> 7) & 1 == 1;
			var dvbt_restream = (restreamactive2 >> 0) & 1 == 1;
			var ndihx_restream = (restreamactive2 >> 1) & 1 == 1;
			var mpegts_restream = (restreamactive2 >> 2) & 1 == 1;
			var rtmp2_restream = (restreamactive2 >> 3) & 1 == 1;

			$("#udp_restream_area").css('display', udp_restream ? 'inline' : 'none');
			$("#rtp_restream_area").css('display', rtp_restream ? 'inline' : 'none');
			$("#ndi_restream_area").css('display', ndi_restream ? 'inline' : 'none');
			$("#ndihx_restream_area").css('display', ndihx_restream ? 'inline' : 'none');
			$("#mpegts_restream_area").css('display', mpegts_restream ? 'inline' : 'none');
			$("#v4l2_restream_area").css('display', v4l2_restream ? 'inline' : 'none');
			$("#dvbt_restream_area").css('display', dvbt_restream ? 'inline' : 'none');

			if (rtmp_restream) {
				$("#rtmp_restream_area").css('display', 'inline');
				$("#rtmp_restream_time").html(rtmptime == 0 ? "" : makeTime(rtmptime));
			} else {
				$("#rtmp_restream_area").css('display', 'none');
				$("#rtmp_restream_time").html('');
			}

			if (rtmp2_restream) {
				$("#rtmp2_restream_area").css('display', 'inline');
				$("#rtmp2_restream_time").html(rtmptime2 == 0 ? "" : makeTime(rtmptime2));
			} else {
				$("#rtmp2_restream_area").css('display', 'none');
				$("#rtmp2_restream_time").html('');
			}

			if (rtsp_restream) {
				$("#rtsp_restream_area").css('display', 'inline');
				$("#rtsp_restream_time").html(rtsptime == 0 ? "" : makeTime(rtsptime));
			} else {
				$("#rtsp_restream_area").css('display', 'none');
				$("#rtsp_restream_time").html('');
			}

			if (srt_restream) {
				$("#srt_restream_area").css('display', 'inline');
				$("#srt_restream_time").html(srttime == 0 ? "" : makeTime(srttime));
			} else {
				$("#srt_restream_area").css('display', 'none');
				$("#srt_restream_time").html('');
			}

			if (onboard_rec) {

                var rec_storage = "";
				if (buf[22] == 1) rec_storage = "MicroSD";
				if (buf[22] == 2) rec_storage = "USB flash";

				var rec_storage_freespace = (((buf[23] + (buf[24] << 8) + (buf[25] << 16) + (buf[26] << 24)))/1000.0).toFixed(3);

				$("#onboard_rec_area").css('display', 'inline');

				if (onboardrectime > 0) {
					$("#onboard_rec_time").html(rec_storage + " " + makeTime(onboardrectime) + " " + rec_storage_freespace + "GB");
				} else {
					$("#onboard_rec_time").html("Waiting video...");
				}

			} else {
				$("#onboard_rec_area").css('display', 'none');
				$("#onboard_rec_time").html('');
			}


			/// Automovements state
			try {
				var amState = {
					state: buf[35],
					current_number: buf[36],
					total_number: buf[37],
					nearest_number: buf[38]
				}

				amParseStatus(amState);

				/*$("#automovements-container").css('display', total_number > 0 ? 'block' : 'none');

				if ($("#am_position_list option").length != total_number) {
					$("#am_position_list").empty();
					for (var i = 0; i < total_number; i++) $("#am_position_list").append('<option value="' + i + '">Position ' + (i + 1) + '</option>');
				}

				$("#am_position_list").prop('selectedIndex', current_number);

				$("#am_numbers").text((current_number + 1) + "/" + total_number);
				$("#am_nearest").text((nearest_number + 1).toString());

				$("#am_auto_enabled").prop('checked', state == 0 ? '' : 'checked');*/

			} catch (e) { console.log(e); }

		break;


		case PACKET_ID.PACKET_CAMERA_BINARY_TELEMETRY:
		case PACKET_ID.PACKET_CAMERA_TEXT_TELEMETRY:
			parseCameraTelemetry(buf);
		break;


		case PACKET_ID.PACKET_WIRAL_STATUS:
			try { WiralParseStatus(buf); } catch (e) { }
		break;

		case PACKET_ID.PACKET_BT_GIMBAL_STATUS:
			try { BtGimbalParseStatus(buf); } catch (e) { }
		break;
	}

}


function parseCameraTelemetry(buf) {
	try {
		parseCamera(buf);
	} catch (e) {}
}


function onAppTypeChanged(type) {
	//console.log("app type changed to " + apptype);

	switch(type) {

		case APP_TYPE.APP_CS_DJI_OSMO:
		case APP_TYPE.APP_CS_DJI_OSMO_WIRED_USB:
		case APP_TYPE.APP_CS_DJI_ZENMUSE:
			$("#right_area").load("tpl/cams/osmo.tpl.html");
		break;

		case APP_TYPE.APP_CS_DJI_ACTION_WIRELESS:
			$("#right_area").load("tpl/cams/osmoaction.tpl.html");
		break;

		case APP_TYPE.APP_CS_DJI_POCKET_WIRELESS:
		case APP_TYPE.APP_CS_DJI_POCKET_USB:
			$("#right_area").load("tpl/cams/pocketosmo.tpl.html");
		break;

		case APP_TYPE.APP_CS_STEREOPI:
			$("#right_area").load("tpl/cams/stereopi.tpl.html");
		break;

		case APP_TYPE.APP_CS_INSTA360EVO_WIRELESS:
			$("#right_area").load("tpl/cams/insta360.tpl.html");
		break;

		case APP_TYPE.APP_CS_OCULUS:
			$("#right_area").load("tpl/cams/oculus.tpl.html");
		break;

		case APP_TYPE.APP_CS_RTSP:
			$("#right_area").load("tpl/cams/rtsp.tpl.html");
		break;

		case APP_TYPE.APP_CS_OBSBOTTAIL:
			$("#right_area").load("tpl/cams/obsbottail.tpl.html");
		break;

		case APP_TYPE.APP_CS_DJI_POCKET2_WIRELESS:
		case APP_TYPE.APP_CS_DJI_POCKET2_USB:
			$("#right_area").load("tpl/cams/pocket2.tpl.html");
		break;

		case APP_TYPE.APP_CS_REMOTE_CLIENT:
			$("#right_area").load("tpl/cams/cs-client.tpl.html");
		break;

		case APP_TYPE.APP_CS_DJI_FPV_GOGGLES:
			$("#right_area").load("tpl/cams/djifpvgoggles.tpl.html");
		break;

		case APP_TYPE.APP_CS_GOPRO:
			$("#right_area").load("tpl/cams/gopro.tpl.html");
		break;

		case APP_TYPE.APP_CS_WEBCAM:
			$("#right_area").load("tpl/cams/webcam.tpl.html");
		break;

		case APP_TYPE.APP_CS_DJI_MINI2:
			$("#right_area").load("tpl/cams/mini2.tpl.html");
		break;

		case APP_TYPE.APP_CS_DJI_AVATA:
			$("#right_area").load("tpl/cams/avata.tpl.html");
		break;

		default:
			$("#right_area").css("display","none");
		break;
	}

	//$("#right_area").css("display","block");
}



function string2Bin(str) {
	var result = [];
	for (var i = 0; i < str.length; i++) {
		result.push(str.charCodeAt(i));
	}
	return result;
}

function bin2String(array) {
	return String.fromCharCode.apply(String, array);
}

function isCameraConnected() {
	return camera_connected;
}


function makeTime(value) {
	var hours = parseInt(value / 3600);
	var minutes = parseInt((value % 3600) / 60);
	var seconds = parseInt(value - (hours * 3600) - minutes * 60);
	var hoursStr = (hours < 10) ? "0" + hours : "" + hours;
	var minutesStr = (minutes < 10) ? "0" + minutes : "" + minutes;
	var secondsStr = (seconds < 10) ? "0" + seconds : "" + seconds;
	return hoursStr + ":" + minutesStr + ":" + secondsStr;
}

function makeTimerStringMs(value_ms) {
    var sec_num = parseInt(value_ms, 10) / 1000;
    var hours   = Math.floor(sec_num / 3600);
    var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
    var seconds = (sec_num - (hours * 3600) - (minutes * 60)).toFixed(3);

    if (hours   < 10) {hours   = "0"+hours;}
    if (minutes < 10) {minutes = "0"+minutes;}
    if (seconds < 10) {seconds = "0"+seconds;}
    //return hours+':'+minutes+':'+seconds;
	return minutes+':'+seconds;
}
