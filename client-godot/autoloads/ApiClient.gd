extends Node
signal completed(id: int, status: int, data: Dictionary)
var csrf := ""
var origin := "http://localhost:5173"
var serial := 0
var _callbacks: Array = []
func _ready() -> void:
	if OS.has_feature("web"):
		origin = str(JavaScriptBridge.get_interface("window").location.origin)
func call_api(path: String, body: Variant = null, method := HTTPClient.METHOD_POST, operation_key := "") -> Dictionary:
	serial += 1
	var request_id := serial
	var http := HTTPRequest.new()
	# Fetch sudah mendekompresi respons proxy pada ekspor Web.
	http.accept_gzip = not OS.has_feature("web")
	add_child(http)
	http.timeout = 15.0
	var headers := PackedStringArray(["Content-Type: application/json", "X-CSRF-Token: " + csrf, "Idempotency-Key: " + (_uuid() if operation_key.is_empty() else operation_key)])
	var payload := "" if body == null else JSON.stringify(body)
	var endpoint := origin + "/api" + path
	var err := http.request(endpoint, headers, method, payload)
	if err != OK:
		http.queue_free()
		return {"ok": false, "error": "Koneksi tidak dapat dimulai."}
	var result: Array = await http.request_completed
	http.queue_free()
	if result[3].is_empty():
		return {"ok":false,"status":int(result[1]),"error":"Koneksi terputus. Coba lagi."}
	var data: Variant = JSON.parse_string(result[3].get_string_from_utf8())
	if not data is Dictionary:
		data = {"error": "Respons server tidak dapat dibaca."}
	data["ok"] = int(result[1]) >= 200 and int(result[1]) < 300 and bool(data.get("ok",true))
	data["status"] = int(result[1])
	if data.has("csrf"):
		csrf = data.csrf
	completed.emit(request_id, int(result[1]), data)
	return data
func get_api(path: String) -> Dictionary:
	return await call_api(path, null, HTTPClient.METHOD_GET)
func _uuid() -> String:
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	return "%s-%s-4%s-a%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(13,3),hex.substr(17,3),hex.substr(20,12)]
