extends Control

const HEART_PATTERN := [
	"03300330",
	"32233223",
	"22222222",
	"22222222",
	"12222221",
	"01222210",
	"00122100"
]

const ARMOR_PATTERN := [
	"0001111000",
	"0012222100",
	"0122222210",
	"1222222221",
	"1222222221",
	"0122222210",
	"0012222100",
	"0001111000"
]

const PIXEL_SIZE := 2.0
const ICON_GAP := 4.0
const HEART_COLORS := [Color(0, 0, 0, 0), Color("#4a171b"), Color("#d7353c"), Color("#ff7770")]
const HEART_EMPTY_COLORS := [Color(0, 0, 0, 0), Color("#291b1b"), Color("#493033"), Color("#604247")]
const ARMOR_COLORS := [Color(0, 0, 0, 0), Color("#303843"), Color("#aab4bd"), Color("#e1e7e8")]
const XP_DARK := Color("#123414")
const XP_GREEN := Color("#65dd32")

var current_health := 20
var maximum_health := 20
var armor_points := 0
var current_xp := 0.0
var xp_to_next := 5.0
var level := 1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_stats(health: int, max_health: int, armor: int, xp: float, xp_goal: float, player_level: int) -> void:
	current_health = maxi(0, health)
	maximum_health = maxi(1, max_health)
	armor_points = clampi(armor, 0, 20)
	current_xp = maxf(0.0, xp)
	xp_to_next = maxf(1.0, xp_goal)
	level = maxi(1, player_level)
	queue_redraw()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor := 2.0 if viewport_size.x >= 1600.0 else 1.0
	var pixel := PIXEL_SIZE * scale_factor
	var heart_width := 8.0 * pixel
	var armor_width := 10.0 * pixel
	var gap := ICON_GAP * scale_factor
	var heart_count := ceili(float(maximum_health) / 2.0)
	var total_width := heart_count * heart_width + maxi(0, heart_count - 1) * gap
	var left := (viewport_size.x - total_width) * 0.5
	var heart_y := viewport_size.y - 72.0 * scale_factor
	var armor_y := heart_y + 18.0 * scale_factor
	var xp_width := minf(300.0 * scale_factor, viewport_size.x - 48.0)
	var xp_height := 7.0 * scale_factor
	var xp_x := (viewport_size.x - xp_width) * 0.5
	var xp_y := viewport_size.y - 27.0 * scale_factor

	for index in heart_count:
		var heart_value := clampi(current_health - index * 2, 0, 2)
		_draw_heart(Vector2(left + index * (heart_width + gap), heart_y), pixel, heart_value)

	var armor_total_width := 10.0 * armor_width + 9.0 * gap
	var armor_left := (viewport_size.x - armor_total_width) * 0.5
	for index in 10:
		var armor_value := clampi(armor_points - index * 2, 0, 2)
		_draw_armor(Vector2(armor_left + index * (armor_width + gap), armor_y), pixel, armor_value)

	draw_rect(Rect2(xp_x - pixel, xp_y - pixel, xp_width + pixel * 2.0, xp_height + pixel * 2.0), Color("#151a12"))
	draw_rect(Rect2(xp_x, xp_y, xp_width, xp_height), XP_DARK)
	var progress := clampf(current_xp / xp_to_next, 0.0, 1.0)
	draw_rect(Rect2(xp_x, xp_y, xp_width * progress, xp_height), XP_GREEN)

	var font := ThemeDB.fallback_font
	var level_text := str(level)
	var font_size := int(14.0 * scale_factor)
	var text_width := font.get_string_size(level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var text_position := Vector2(viewport_size.x * 0.5 - text_width * 0.5, xp_y - 3.0 * scale_factor)
	draw_string_outline(font, text_position, level_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, 3, Color("#11150d"))
	draw_string(font, text_position, level_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color.WHITE)


func _draw_heart(position: Vector2, pixel: float, health_value: int) -> void:
	for row in range(HEART_PATTERN.size()):
		for column in range(HEART_PATTERN[row].length()):
			var cell := int(HEART_PATTERN[row].substr(column, 1))
			if cell == 0:
				continue
			var filled := health_value == 2 or (health_value == 1 and column < 4)
			var color: Color = HEART_COLORS[cell] if filled else HEART_EMPTY_COLORS[cell]
			draw_rect(Rect2(position + Vector2(column, row) * pixel, Vector2.ONE * pixel), color)


func _draw_armor(position: Vector2, pixel: float, armor_value: int) -> void:
	for row in range(ARMOR_PATTERN.size()):
		for column in range(ARMOR_PATTERN[row].length()):
			var cell := int(ARMOR_PATTERN[row].substr(column, 1))
			if cell == 0:
				continue
			var filled := armor_value == 2 or (armor_value == 1 and column < 5)
			var color: Color = ARMOR_COLORS[cell] if filled else Color("#292e31")
			draw_rect(Rect2(position + Vector2(column, row) * pixel, Vector2.ONE * pixel), color)
