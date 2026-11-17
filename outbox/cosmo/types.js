const PACKET_ID = {
	PACKET_DISCOVERY: 0,
	PACKET_DISCOVERY_ANSWER: 1,
	PACKET_CLIENT_ALIVE: 2,
	PACKET_CLIENT_GONE: 3,
	PACKET_SERVER_STATUS: 4,
	PACKET_CLIENT_BINARY_DATA: 5,
	PACKET_CAMERA_BINARY_TELEMETRY: 6,
	PACKET_CAMERA_TEXT_TELEMETRY: 7,
	PACKET_SERVER_RC_MENU: 8,
	PACKET_PREVIEW_REQUEST: 9,
	PACKET_PREVIEW_ANSWER: 10,
	PACKET_WIRAL_STATUS: 11,
	PACKET_BT_GIMBAL_STATUS: 12
}

const T_TYPE = {
	BINARY_TELEMETRY1: 0,
	BINARY_TELEMETRY2: 1,
	BINARY_TELEMETRY3: 2,
}


const APP_TYPE = {
	APP_CS_DJI_OSMO: 0, /// Cosmostreamer for Osmo (Wi-Fi connection)							0
	APP_CS_DJI_OSMO_WIRED_USB: 1, /// Cosmostreamer for Osmo Pro/RAW with Wired video adapter	1
	APP_CS_DJI_ZENMUSE: 2, /// Cosmostreamer Wired (USB connection)								2
	APP_CS_DJI_POCKET_USB: 3, /// Cosmostreamer for Pocket Osmo with USB connection				3
	APP_CS_DJI_POCKET_WIRELESS: 4, /// Cosmostreamer for Pocket Osmo with Wi-Fi connection		4
	APP_CS_DJI_ACTION_WIRELESS: 5, /// Cosmostreamer for Osmo Action with Wi-Fi connection		5
	APP_CS_GOPRO: 6, 		/// Cosmostreamer for GoPro											6
	APP_CS_XIAOMI_YI_WIRELESS: 7, /// Cosmostreamer for Xiaomi Yi cams with Wi-Fi connection	7
	APP_CS_PHANTOM_USB: 8, /// Cosmostreamer for Phantom and other DJI Go4 drones				8
	APP_CS_STEREOPI: 9, /// Cosmostreamer for StereoPi/Raspberry Pi								9
	APP_CS_INSTA360EVO_WIRELESS: 10, /// Insta360 EVO Wi-Fi										10
	APP_CS_OCULUS: 11, /// Oculus Go/Quest														11
	APP_CS_OBSBOTTAIL: 12, /// OBSBOT Tail														12
	APP_CS_RTSP: 13, /// RTSP/ONVIF camera														13
	APP_CS_DJI_POCKET2_USB: 14, /// Cosmostreamer for Pocket 2 with USB connection				14
	APP_CS_DJI_POCKET2_WIRELESS: 15, /// Cosmostreamer for Pocket 2 with Wi-Fi connection		15
	APP_CS_REMOTE_CLIENT: 16, /// Cosmostreamer remote client									16
	APP_CS_DJI_FPV_GOGGLES: 17, /// DJI FPV Goggles												17
	APP_CS_NDI_RECEIVER: 18, /// NDI receiver													18
	APP_CS_RTMP_RECEIVER: 19, /// RTMP receiver													19	
	APP_CS_DJI_RAVEN_EYE: 20, /// DJI Raven Eye													20
	APP_CS_WEBCAM: 21, 		  /// UVC Webcams													21
	APP_CS_DJI_MINI2: 22, 	  /// DJI Mini2 and other DJI Fly drones							22
	APP_CS_DJI_AVATA: 23, 	  /// DJI Avata/O3													23
	APP_CS_JETSON_CAMERA:24   /// Jetson Nano camera											24
}


const app_types_array = [
	"DJI Osmo Wi-Fi",
	"DJI Osmo Pro/RAW with Wired adapter",
	"DJI Zenmuse",
	"DJI Pocket Osmo USB",
	"DJI Pocket Osmo Wi-Fi",
	"DJI Osmo Action",
	"GoPro",
	"Xiaomi Yi",
	"DJI Phantom4 USB",
	"StereoPi/RaspberryPi",
	"Insta360",
	"Oculus Go/Quest/Quest2 (and any Android)",
	"OBSBOT Tail",
	"RTSP/ONVIF camera",
	"DJI Pocket 2 USB",
	"DJI Pocket 2 Wi-Fi",
	"Remote client",
	"DJI FPV Goggles V1/V2",
	"NDI receiver",
	"RTMP receiver",
	"DJI RavenEye",
	"UVC Webcam",
	"DJI Mini2/Mini3",
	"DJI Goggles2/Integra with Avata/O3",
	"Jetson Nano Camera"
]


const GIMBAL_TYPE = {
	GMB_NONE: 0,
	GMB_ZHIYUN_RIDER_M: 1,
	GMB_DJI_RONIN_SC: 2
}


const gimbal_types_array = [
	"",
	"Zhiyun Rider M",
	"DJI Ronin SC"
]


const rc_state_array = [
	"",
	"",
	"Cal min/max",
	"Cal min/max finished",
	"Cal center",
]

