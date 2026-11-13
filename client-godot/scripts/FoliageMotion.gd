extends RefCounted

static func gust(seconds: float, position: Vector2, speed := 1.0) -> float:
	var phase:=seconds*.68*speed-position.x/185.0-position.y/420.0
	var crest:=maxf(0.0,sin(phase))
	return crest*crest*crest*crest

static func land_offset(seconds: float, position: Vector2, wind: float, pixel_step: float, size := 1.0) -> float:
	var stepped:=floorf(seconds*10.0)/10.0
	var strength:=gust(stepped,position)*clampf(wind/22.0,.35,1.4)
	var wave:=sin(stepped*4.0-position.x/69.0-position.y/190.0)
	var distance:=(1.6+wave*.65)*strength*size
	return roundf(distance/maxf(.2,pixel_step))*pixel_step

static func current_angle(seconds: float, position: Vector2, speed := 1.0) -> float:
	var stepped:=floorf(seconds*10.0)/10.0
	var strength:=gust(stepped,position,speed)
	return sin(stepped*2.7-position.x/120.0-position.y/280.0)*strength*.032
