extends "res://autoloads/ApiClient.gd"
var calls:Array=[]
var accept_start:=true
func call_api(path:String,body:Variant=null,_method:=HTTPClient.METHOD_POST,_operation_key:="") -> Dictionary:
	calls.append({"path":path,"body":body.duplicate(true) if body is Dictionary else body})
	await get_tree().process_frame
	if path=="/kedai/start" and accept_start:
		return {"ok":true,"shift":GameState.shift.duplicate(true)}
	return {"ok":false,"code":"INVALID","error":"Penolakan server fixture; tidak ada koneksi atau transaksi nyata."}
