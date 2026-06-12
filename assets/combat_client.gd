extends SceneTree
# Replays the Lean golden script against the authoritative server and asserts
# every effect reply matches the Lean core's trace, in order.
var GOLDEN: String = OS.get_environment("COMBAT_GOLDEN")
var peer: WebTransportPeer
var events: PackedStringArray = []
var expected: PackedStringArray = []
var idx := 0; var sent := false; var t0 := 0

func _init():
	var f = FileAccess.open(GOLDEN, FileAccess.READ)
	while not f.eof_reached():
		var line = f.get_line()
		if line == "": continue
		var parts = line.split(";")
		events.append(parts[0]); expected.append(parts[1])
	peer = WebTransportPeer.new()
	if peer.create_client("127.0.0.1", 54371, "/wt") != OK:
		printerr("client create failed"); quit(1)
	t0 = Time.get_ticks_msec()

func _process(_d: float) -> bool:
	if not peer: return false
	peer.poll()
	if Time.get_ticks_msec() - t0 > 30000:
		printerr("TIMEOUT at ", idx, "/", events.size()); quit(1); return false
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not sent:
			sent = true
			for e in events: peer.put_packet(e.to_utf8_buffer())
		while peer.get_available_packet_count() > 0:
			var got = peer.get_packet().get_string_from_utf8()
			if got != expected[idx]:
				printerr("MISMATCH @", idx, " event=", events[idx], " wire=", got, " golden=", expected[idx])
				quit(1); return false
			idx += 1
			if idx == events.size():
				print("COMBAT WIRE PARITY PASS: ", idx, " server-authoritative effects match the Lean trace")
				quit(0)
	return false
