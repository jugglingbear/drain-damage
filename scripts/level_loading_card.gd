extends RefCounted
## Loading illustration and input shared by the title and level transitions.

const ART_ROOT := "res://assets/ui/loading-cards/"
const PANEL := Color("10212a")
const BRASS := Color("f3bd63")
const PIPE := Color("243638")
const FILL := Color("75d5ad")

var illustration: Texture2D

func begin(level: String) -> void:
	var path := ART_ROOT+level+"-"+str(randi_range(1,2))+".webp"
	illustration = load(path) if ResourceLoader.exists(path) else null

func accepts(event: InputEvent) -> bool:
	if event is InputEventKey: return event.pressed and not event.echo
	if event is InputEventJoypadButton: return event.pressed
	if event is InputEventMouseButton: return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false

func draw(host: CanvasItem, progress: float, ready: bool) -> void:
	var screen := host.get_viewport_rect()
	host.draw_rect(screen,PANEL)
	if illustration: host.draw_texture_rect(illustration,screen,false)
	var center := screen.get_center().x
	var bottom := screen.end.y
	host.draw_rect(Rect2(screen.position.x,bottom-83,screen.size.x,83),Color("10212af2"))
	var bar := Rect2(center-192,bottom-65,384,16)
	host.draw_rect(bar,BRASS)
	host.draw_rect(bar.grow(-2),PIPE)
	var segments := clampi(floori(progress*24),0,24)
	for i in segments:
		host.draw_rect(Rect2(bar.position+Vector2(4+i*15.75,4),Vector2(13,8)),FILL)
	var label := "LOADING   %d%%" % floori(clampf(progress,0,1)*100)
	if ready:
		label = "PRESS ANY BUTTON TO PLAY!"
	var tint := BRASS if not ready or Time.get_ticks_msec()%1000 < 700 else Color("ba9862")
	host.draw_string(ThemeDB.fallback_font,Vector2(screen.position.x,bottom-19),label,
		HORIZONTAL_ALIGNMENT_CENTER,screen.size.x,20,tint)
