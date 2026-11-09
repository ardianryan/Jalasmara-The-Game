extends RefCounted

var clip := "idle"
var elapsed := 0.0
var distance := 0.0
var direction := "south"
var movement_locked := false
var events: Array[String] = []
var frame := 0
var _work_kind := ""
var _step_index := 0
var _last_action_index := -1
var _last_phase := ""
var _talking := false

func begin_departure() -> void:
	if clip in ["start_work","work_loop"]:
		_change("end_work")
		movement_locked=true

func _change(next: String) -> void:
	if next==clip: return
	clip=next
	elapsed=0
	_last_action_index=-1
	_last_phase=""

func update(delta: float,velocity: Vector2,working: bool,resting: bool,talking: bool,paused: bool,reduced: bool,kind: String) -> void:
	events.clear()
	_work_kind=kind
	if velocity.length()>.1:
		direction=("east" if velocity.x>0 else "west") if absf(velocity.x)>absf(velocity.y)*.8 else ("south" if velocity.y>0 else "north")
	if paused and not talking: return
	if talking:
		if clip in ["start_work","work_loop"]: begin_departure()
		if clip!="end_work": _change("interact")
	elif clip=="interact": _change("idle")
	if clip=="end_work":
		elapsed+=delta
		movement_locked=true
		if elapsed>=.65:
			movement_locked=false
			_change("interact" if talking else "idle")
	elif velocity.length()>.1:
		_change("walk")
		distance+=velocity.length()*delta
		elapsed=distance/25.0
		var step:=floori(distance/12.5)
		if step!=_step_index:
			_step_index=step
			events.append("step")
	elif working and not talking:
		if clip not in ["start_work","work_loop"]: _change("start_work")
		elapsed+=delta
		if clip=="start_work" and elapsed>=.8: _change("work_loop")
	elif resting and not talking:
		_change("rest")
		elapsed+=delta
	elif not talking:
		_change("idle")
		elapsed+=delta
	else: elapsed+=delta
	frame=floori(elapsed*8)%8
	if reduced: frame=0
	var phase:=work_phase()
	if clip=="work_loop" and not reduced:
		var index:=floori(elapsed/(.45 if kind=="gardening" else .8))
		if index!=_last_action_index:
			_last_action_index=index
			if kind=="gardening" and phase=="pour": events.append("water_drop")
		if phase!=_last_phase and phase in ["cast","pull","inspect"]: events.append(phase)
	_last_phase=phase

func work_phase() -> String:
	if clip=="start_work": return "prepare"
	if clip=="end_work": return "tidy"
	if clip!="work_loop": return clip
	if _work_kind=="fishing":
		var t:=fposmod(elapsed,9)
		return "prepare" if t<1.0 else "cast" if t<1.8 else "wait" if t<6.7 else "pull" if t<8 else "tidy"
	if _work_kind=="gardening":
		var t:=fposmod(elapsed,5.2)
		return "lift" if t<.9 else "aim" if t<1.5 else "pour" if t<4.1 else "lower"
	if _work_kind=="weaving": return "inspect" if fposmod(elapsed,5.8)>4.6 else "weave"
	return "inspect" if fposmod(elapsed,4)>3 else "work"

func snapshot() -> Dictionary:
	return {"clip":clip,"frame":frame,"elapsed":elapsed,"direction":direction,"distance":distance,"workPhase":work_phase(),"movementLocked":movement_locked,"events":events.duplicate()}
