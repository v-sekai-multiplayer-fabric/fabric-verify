extends SceneTree
# Server-authoritative combat: the CombatCore.step reducer (transcribed from the
# proven Lean core) running behind WebTransportPeer. One datagram = one event;
# the reply is the effect list ("-" when empty).
const PORT = 54371
const MIN_GAP = 6; const MAX_GAP = 18; const INVULN = 30; const MAX_HP = 100
var tick := 0; var combo := 0; var last_attack := 0
var hp := 0; var spawn_tick := 0; var alive := false
var peer: WebTransportPeer

static func _fmt(t: int) -> String:
	var d = Time.get_datetime_dict_from_unix_time(t)
	return "%04d%02d%02d%02d%02d%02d" % [d.year, d.month, d.day, d.hour, d.minute, d.second]

func dmg(stage: int) -> int: return [10, 15, 25][stage]

func resolve_swing(stage: int) -> Array:
	if not alive: return ["swing%d" % stage]
	if tick < spawn_tick + INVULN: return ["swing%d" % stage, "blocked"]
	var d := dmg(stage)
	if hp <= d:
		hp = 0; alive = false
		return ["swing%d" % stage, "hit%d" % d, "death"]
	hp -= d
	return ["swing%d" % stage, "hit%d" % d]

func step(ev: String) -> Array:
	match ev:
		"tick":
			tick += 1
			if combo > 0 and tick > last_attack + MAX_GAP:
				combo = 0; return ["comboDrop"]
			return []
		"spawn":
			alive = true; hp = MAX_HP; spawn_tick = tick
			return []
		"attack":
			if combo == 0:
				combo = 1; last_attack = tick
				return resolve_swing(0)
			var gap := tick - last_attack
			if MIN_GAP <= gap and gap <= MAX_GAP:
				var stage := combo
				combo = 0 if stage >= 2 else stage + 1
				last_attack = tick
				return resolve_swing(stage)
			combo = 0; return ["whiff"]
	return []

func _init():
	var crypto = Crypto.new()
	var key = crypto.generate_ecdsa()
	var now = int(Time.get_unix_time_from_system())
	var cert = crypto.generate_self_signed_certificate_san(key, "CN=combat-zone",
		_fmt(now), _fmt(now + 86400), PackedStringArray(["DNS:localhost", "IP:127.0.0.1"]))
	peer = WebTransportPeer.new()
	if peer.create_server(PORT, "/wt", cert, key) != OK:
		printerr("create_server failed"); quit(1); return
	print("COMBATSRV ready on ", PORT)

func _process(_d: float) -> bool:
	if not peer: return false
	peer.poll()
	while peer.get_available_packet_count() > 0:
		var fx := step(peer.get_packet().get_string_from_utf8())
		peer.put_packet(("-" if fx.is_empty() else "+".join(fx)).to_utf8_buffer())
	return false
