## Global utility for making concurrent network
## https://docs.godotengine.org/en/stable/tutorials/networking/http_request_class.html
extends Node


func _async_post(url: String, req_body: Variant) -> Variant:
	var api_url: String = Bootstrap.backend_url

	# Create new node for each request to allow parallel requests
	var http := HTTPRequest.new()
	http.accept_gzip = false
	add_child(http)

	while true:
		var err = http.request(api_url.path_join(url),
			[
				"Content-Type: application/json",
			],
			HTTPClient.METHOD_POST,
			JSON.stringify(req_body)
		)

		if err != OK:
			var err_str = error_string(err)
			push_error("HTTP request failed to start: %s (%d)" % [err_str, err])
			Events.network_error.emit("HTTP request failed to start: %s (%d)" % [err_str, err])
			await Events.network_retrying
			continue

		var res = await http.request_completed

		var result: int = res[0]
		var response_code: int = res[1]
		# var headers: String = res[2]
		var res_body = res[3]

		if result != HTTPRequest.RESULT_SUCCESS:
			push_error("HTTP Error: %d" % result)
			Events.network_error.emit("HTTP Error: %d" % result)
			await Events.network_retrying
			continue
		if response_code != 200:
			push_error("API Error: %d" % response_code)
			Events.network_error.emit("API Error: %d" % response_code)
			await Events.network_retrying
			continue

		var json := JSON.new()
		var json_string = res_body.get_string_from_utf8()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			http.queue_free()
			return json.data
		else:
			var err_str = error_string(parse_result)
			var err_msg = json.get_error_message()
			push_error("JSON Parse Error: %s (%s) at line %d in %s" % [err_msg, err_str, json.get_error_line(), json_string])
			Events.network_error.emit("JSON Parse Error: %s (%s) at line %d" % [err_msg, err_str, json.get_error_line()])
			await Events.network_retrying
			continue
	
	assert(false, "Exited network loop without response")
	http.queue_free()
	return null
