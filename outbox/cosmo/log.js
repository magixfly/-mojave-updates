function show_log(message) {
	var text = $("#log_area").html();
	$("#log_area").html(text + "<p>" + message + "</p>");
}
