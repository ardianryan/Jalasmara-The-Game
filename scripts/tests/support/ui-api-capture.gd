extends "res://autoloads/ApiClient.gd"
var calls:Array=[]
func call_api(path:String,body:Variant=null,_method:=HTTPClient.METHOD_POST,_operation_key:="") -> Dictionary:
	calls.append({"path":path,"body":body.duplicate(true)})
	await get_tree().process_frame
	return {"ok":false,"error":"Tangkapan payload fixture saja; tidak dikirim ke server."}
