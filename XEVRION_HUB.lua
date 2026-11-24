local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LP:WaitForChild("PlayerGui")

local K = {
	SPEED = 350,
	MIN_SPEED = 50,
	MAX_SPEED = 1500,
	SPEED_STEP = 50,

	CAMERA_HEIGHT = 6,
	CAMERA_FOLLOW = 14,
	CAMERA_SENSITIVITY = 0.0035,
	MOUSE_SENSITIVITY = 0.0025,
	CAMERA_SMOOTHING = 40,
	LOCK_SMOOTHING = 9,
	IMPACT_DIST = 6,
	RADAR_SIZE = 170,
	RADAR_RATE = 0.2,
	SWEEP_SPEED = 120,
	BLIP_FADE = 1.5,
	TRAIL_COUNT = 5,
	TRAIL_STEP = 4,
	HUD_RATE = 1 / 15,
	MAX_PITCH = math.rad(85),

	MENU_W = 560,
	MENU_H = 315,
	MAX_MENU_BASE_SCALE = 0.8,

	MIN_LAYOUT_SCALE = 0.5,
	MAX_LAYOUT_SCALE = 1.6,
	SCALE_STEP = 0.05,
}

local DEFAULT_SCALE = {
	toggle = 1,
	menu = 1,
	telemetry = 0.8,
	heading = 0.85,
	speedTape = 0.85,
	altTape = 0.85,
	radar = 0.8,
	bottom = 0.85,
	pad = 0.8,
	eject = 0.85,
	targetInfo = 1,
	next = 0.85,
	swarm = 0.85,
}

local Store = {
	KEY = "DroneHUDLayout_v1",
	FILE = "DroneHUD_Layout_v2.json",
	dirty = false,
	queued = false,
}
local InfoCard = {}

local Cfg = {
	friendCheck = true,
	fov = 70,
	camDist = 25,
	speedFx = true,
	noSignal = true,
	sens = 100,
	boost = 200,
	lang = "EN",
	radarRange = 800,
	friends = {},
	friendAsked = {},

	swarmMax = 8,
	swarmScatter = 3,
	swarmSpeed = 300,
	swarmHeight = 10,
	swarmRadius = 8,
	swarmOrbit = 90,
	swarmSpread = 40,
	swarmCollapsed = false,

	tgtDist = 30,
	tgtOrbit = 90,
	tgtDelay = 0,

	tnRadius = 30,
	tnHeight = 25,
	tnSpeed = 180,
	tnDelay = 0,

	tgtHeight = 4,
	tnLift = 0,
	spinPower = 1500,

	scTime = 3,
	scDist = 60,
	scSpin = 360,
	scSpeed = 300,

	nHeight = 80,
	nGap = 1,

	cinema = true,

	lagLevel = 0,
	autoLag = false,
	fxId = "classic",
	fxSize = 100,
	fxTime = 100,
	fxColor = 0,
	skinId = "original",
	skinCustom = "",

	sndPack = "auto",
	sndVol = 100,
	sndCustom = "",
	shake = 100,
	slowmo = 0,
	trailId = "none",
	trailSize = 100,
	swarmFx = 0,
	cineStyle = "auto",
	cineBars = true,
	cineShake = 100,
	cineDist = 100,
}

local FX = {
	RADAR_RANGES = { 400, 800, 1500 },
	STATIC_SOUND_ID = "",
	speedK = 0,
	lt = 0,
	aim = nil,
	origFov = 70,
	nsBusy = false,
	linesOn = false,
	setters = {},
	togglers = {},
	binds = {},
	boostUntil = 0,
	boostReadyAt = 0,
	boostTime = 2,
	boostCooldown = 5,
	boostText = "",
	statusActive = false,

	hitT = nil,
	hitAway = Vector3.new(0, 1, 0),
	autoAtk = false,
	lastBombPos = nil,
	hitContact = 0.3,
	hitRetreat = 0.4,
}

FX.conns = {}
FX.dead = false

function FX.conn(sig, fn)
	local c = sig:Connect(function(...)
		if FX.dead then
			return
		end

		return fn(...)
	end)

	table.insert(FX.conns, c)

	return c
end

local SW = {
	bombs = {}, angle = 0, lockOn = false, lockRoot = nil, msgUntil = 0,
	mode = "swarm",
	wantMode = "swarm",
	spinT0 = 0,
	spinDur = 3,
	spinUntil = nil,
	gapUntil = 0,
	listBtns = {},
}

FX.V2 = {
	on = false,
	center = nil,
	sats = {},
	fin = {},
	flying = false,
	slowT0 = nil,
}

function FX.V2.satParts()
	local list = {}

	for _, s in ipairs(FX.V2.sats) do
		table.insert(list, s.part)
	end

	for _, s in ipairs(FX.V2.fin) do
		table.insert(list, s.part)
	end

	return list
end

FX.STR = {
	EN = {
		title = "XEVRION HUB",
		subtitle = "FPV BOMB SYSTEM  •  drag me",
		standby = "STANDBY",
		active = "ACTIVE",
		sec_target = "TARGET",
		sec_flight = "FLIGHT",
		sec_lockfilter = "LOCK FILTER",
		sec_camera = "CAMERA",
		sec_language = "LANGUAGE",
		btn_bomb = "💣 SELECT BOMB",
		btn_bomb_ok = "💣 BOMB SELECTED",
		btn_bomb_none = "💣 NO BOMB FOUND",
		btn_drone_off = "🚁 DRONE: OFF",
		btn_drone_on = "🚁 DRONE: ON",
		btn_drone_nobomb = "🚁 NO BOMB SELECTED",
		btn_edit = "🛠 EDIT HUD",
		pk_title = "BOMB PICKER",
		pk_hint = "Aim the dot at a bomb, then tap SELECT BOMB.",
		pk_hint2 = "Aim the dot at a bomb, then tap ADD.",
		pk_menu = "MENU",
		speed = "SPEED",
		tg_friend = "FRIEND CHECK",
		tg_speedfx = "SPEED FX",
		tg_nosignal = "NO SIGNAL",
		st_fov = "FOV",
		st_camdist = "CAMERA DISTANCE",
		st_sens = "CAMERA SENSITIVITY",
		hint = "F Drone  •  L Lock  •  T Next  •  B Boost  •  R Radar\nQ/E Speed  •  WASD Move\nSwipe / hold RMB to look\nSwarm / Orbit / Tornado / Scatter: V Add  •  G Launch / Attack",
		m_noother = "NO OTHER TARGET",
		m_switched = "TARGET SWITCHED",
		m_notarget = "NO TARGET",
		m_locked = "TARGET LOCKED",
		m_lockbroken = "LOCK BROKEN",
		m_targetlost = "TARGET LOST",
		m_link = "DRONE LINK ESTABLISHED",
		m_radar = "RADAR RANGE",
		m_boost = "BOOST!",
		m_boost_cd = "BOOST NOT READY",
		lock_lbl = "LOCK",
		tgt_behind = "TGT BEHIND",
		rng = "RNG",
		eject = "EJECT",
		next = "NEXT ▶",
		boost = "BOOST",
		st_boost = "BOOST POWER",
		lock_on = "LOCK: ON",
		lock_off = "LOCK: OFF",
		ns_title = "NO SIGNAL",
		ns_sub = "VIDEO LINK LOST",
		ns_a = "[!] LINK ERROR",
		ns_b = "RECONNECTING...",
		ed_title = "UI EDITOR",
		ed_hint = "Drag to move  •  tap to select  •  auto-saved",
		ed_select = "TAP A BOX TO SELECT",
		ed_size = "SIZE",
		ed_reset = "RESET",
		ed_resetall = "RESET ALL",
		ed_done = "DONE",
		el_toggle = "TOGGLE",
		el_menu = "MENU",
		el_heading = "HEADING",
		el_telemetry = "TELEMETRY",
		el_speedTape = "SPEED TAPE",
		el_altTape = "ALTITUDE",
		el_eject = "EJECT",
		el_bottom = "SPEED / LOCK",
		el_next = "NEXT TARGET",
		el_pad = "DIRECTION PAD",
		el_radar = "RADAR",
		el_targetInfo = "TARGET INFO",
		el_boost = "BOOST",
		sec_swarm = "SWARM STRIKE",
		btn_swarm_add = "💣 ADD SWARM BOMB",
		btn_swarm_clear = "🗑 CLEAR SWARM",
		st_swarm_max = "MAX BOMBS",
		st_swarm_scatter = "SCATTER TIME",
		st_swarm_spread = "SPREAD RADIUS",
		st_swarm_speed = "SWARM SPEED",
		st_swarm_height = "ORBIT HEIGHT",
		st_swarm_radius = "ORBIT RADIUS",
		st_swarm_orbit = "ORBIT SPEED",
		sw_title = "SWARM",
		sw_add = "ADD +",
		sw_clear = "CLEAR",
		sw_launch = "🚀 LAUNCH",
		sw_orbit = "ORBIT",
		sw_launched = "LAUNCHED",
		sw_tgt = "TGT",
		sw_added = "BOMB ADDED",
		sw_full = "SWARM FULL",
		sw_empty = "NO BOMBS IN ORBIT",
		sw_go = "SWARM LAUNCHED",
		sw_hit = "TARGET HIT",
		sw_back = "TARGET LOST - RETURNING",
		sw_recall = "SWARM RECALLED",
		sw_cleared = "SWARM CLEARED",
		el_swarm = "SWARM PANEL",
		tab_drone = "DRONE",
		tab_drone2 = "DRONE V2",
		v2_ready = "💣 5/5 READY",
		v2_cleared = "💣 SELECTION CLEARED",
		v2_dup = "💣 ALREADY SELECTED",
		v2_launch = "LAUNCHING UP...",
		v2_ctrl = "CONTROL READY",
		tab_swarm = "SWARM",
		tab_orbit = "ORBIT",
		sec_orbit = "ORBIT TARGET",
		sec_orbit_pick = "PICK TARGET",
		btn_orbit_attack = "💥 ATTACK",
		btn_orbit_refresh = "🔄 REFRESH PLAYERS",
		st_tgt_dist = "ORBIT DISTANCE",
		st_tgt_orbit = "ORBIT SPEED",
		st_tgt_delay = "ATTACK DELAY",
		or_none = "NO PLAYERS FOUND",
		or_set = "TARGET SELECTED",
		or_pick = "PICK A TARGET FIRST",
		or_spin = "SPINNING UP...",
		or_busy = "SWARM BUSY - WAIT",
		tab_tornado = "TORNADO",
		sec_tornado = "TORNADO",
		st_tn_radius = "TORNADO WIDTH",
		st_tn_height = "TORNADO HEIGHT",
		st_tn_speed = "TORNADO SPEED",
		st_tn_delay = "ATTACK DELAY",
		st_spin = "SPIN POWER",
		tab_scatter = "SCATTER",
		sec_scatter = "SCATTER STRIKE",
		st_sc_time = "SCATTER TIME",
		st_sc_dist = "SCATTER DISTANCE",
		st_sc_spin = "SCATTER SPIN",
		st_sc_speed = "ATTACK SPEED",
		sc_go = "SCATTER LAUNCHED",
		sc_retry = "NOT EXPLODED - HIT AGAIN",
		sc_nolock = "SCATTER = RANDOM TARGETS",
		sc_random = "RANDOM",
		sc_lost = "TARGET LOST - NEW TARGET",
		st_n_height = "DIVE HEIGHT",
		st_n_gap = "BOMB INTERVAL",
		tg_cinema = "CINEMATIC CAM",
		tab_settings = "⚙ SETTINGS",
		tab_visual = "🎨 VISUAL",
		sec_antilag = "ANTI-LAG",
		st_lag = "ANTI-LAG LEVEL",
		tg_autolag = "AUTO ANTI-LAG",
		lag_hint = "OFF = best graphics.\nLOW = no shadows / post effects.\nMEDIUM = + low quality, no map particles.\nHIGH = + plain materials, max FPS.\nAUTO raises the level when FPS stays low.",
		sec_skin = "BOMB TEXTURE PACK",
		sec_skin_custom = "CUSTOM TEXTURE ID (numbers only)",
		btn_skin_apply = "APPLY TO BOMBS",
		skin_hint = "The pack is put on the bomb you select or add. Only you can see it.",
		sec_fx = "EXPLOSION EFFECT",
		st_fx_size = "EXPLOSION SIZE",
		st_fx_time = "EXPLOSION DURATION",
		st_fx_color = "EXPLOSION COLOR",
		btn_fx_preview = "▶ PREVIEW EXPLOSION",
		fx_hint = "Visual only (client side). Other players see the normal game explosion.",
		tab_fx = "💥 FX",
		tab_cinema = "🎬 CINEMA",
		sec_sound = "EXPLOSION SOUND",
		sec_sound_custom = "CUSTOM SOUND ID (numbers only)",
		st_snd_vol = "SOUND VOLUME",
		btn_snd_test = "▶ TEST SOUND",
		snd_hint = "AUTO picks a sound that fits each effect. CLASSIC keeps the normal game sound. Tap a pack to hear it.",
		sec_trail = "BOMB TRAIL",
		st_trail_size = "TRAIL SIZE",
		trail_hint = "The trail is put on the bomb you select or add. Only you can see it.",
		sec_impact = "IMPACT",
		st_shake = "CAMERA SHAKE",
		st_slow = "SLOW MOTION",
		impact_hint = "SLOW MOTION slows the explosion visuals and sound and zooms the camera in. The cinematic camera holds longer too. The game itself cannot be slowed down.",
		st_swarmfx = "SWARM EFFECT MODE",
		swarmfx_hint = "SAME = the effect you chose. RANDOM EACH = every swarm bomb gets its own random effect. CYCLE = the effects one after another.",
		sec_cinema = "CINEMATIC CAMERA",
		sec_cine_style = "CAMERA STYLE",
		tg_cinebars = "BLACK BARS",
		st_cine_shake = "IMPACT SHAKE",
		st_cine_dist = "SHOT DISTANCE",
		cine_hint = "The cinematic camera works in the SWARM / ORBIT / TORNADO / SCATTER tabs (not the drone). It starts when the bombs launch. RANDOM picks a new style for every bomb.",
	},
	ID = {
		title = "XEVRION HUB",
		subtitle = "BOM FPV  •  geser aku",
		standby = "SIAGA",
		active = "AKTIF",
		sec_target = "TARGET",
		sec_flight = "TERBANG",
		sec_lockfilter = "FILTER KUNCI",
		sec_camera = "KAMERA",
		sec_language = "BAHASA",
		btn_bomb = "💣 PILIH BOM",
		btn_bomb_ok = "💣 BOM DIPILIH",
		btn_bomb_none = "💣 BOM TIDAK ADA",
		btn_drone_off = "🚁 DRONE: MATI",
		btn_drone_on = "🚁 DRONE: NYALA",
		btn_drone_nobomb = "🚁 BELUM PILIH BOM",
		btn_edit = "🛠 ATUR HUD",
		pk_title = "PILIH BOM",
		pk_hint = "Arahkan titik ke bom, lalu tekan PILIH BOM.",
		pk_hint2 = "Arahkan titik ke bom, lalu tekan TAMBAH.",
		pk_menu = "MENU",
		speed = "KECEPATAN",
		tg_friend = "CEK TEMAN",
		tg_speedfx = "EFEK KECEPATAN",
		tg_nosignal = "TANPA SINYAL",
		st_fov = "FOV",
		st_camdist = "JARAK KAMERA",
		st_sens = "SENSITIVITAS KAMERA",
		hint = "F Drone  •  L Kunci  •  T Berikut  •  B Boost  •  R Radar\nQ/E Kecepatan  •  WASD Gerak\nGeser layar / tahan klik kanan untuk melihat\nSwarm / Orbit / Tornado / Sebar: V Tambah  •  G Luncurkan / Serang",
		m_noother = "TIDAK ADA TARGET LAIN",
		m_switched = "TARGET DIGANTI",
		m_notarget = "TIDAK ADA TARGET",
		m_locked = "TARGET TERKUNCI",
		m_lockbroken = "KUNCI PUTUS",
		m_targetlost = "TARGET HILANG",
		m_link = "KONEKSI DRONE TERHUBUNG",
		m_radar = "JANGKAUAN RADAR",
		m_boost = "BOOST!",
		m_boost_cd = "BOOST BELUM SIAP",
		lock_lbl = "KUNCI",
		tgt_behind = "TARGET DI BELAKANG",
		rng = "JRK",
		eject = "KELUAR",
		next = "BERIKUT ▶",
		boost = "BOOST",
		st_boost = "KEKUATAN BOOST",
		lock_on = "KUNCI: NYALA",
		lock_off = "KUNCI: MATI",
		ns_title = "TANPA SINYAL",
		ns_sub = "KONEKSI VIDEO TERPUTUS",
		ns_a = "[!] ERROR KONEKSI",
		ns_b = "MENYAMBUNG ULANG...",
		ed_title = "EDITOR UI",
		ed_hint = "Geser untuk pindah  •  tap untuk pilih  •  tersimpan otomatis",
		ed_select = "TAP KOTAK UNTUK MEMILIH",
		ed_size = "UKURAN",
		ed_reset = "ULANG",
		ed_resetall = "ULANG SEMUA",
		ed_done = "SELESAI",
		el_toggle = "TOMBOL BUKA",
		el_menu = "MENU",
		el_heading = "ARAH",
		el_telemetry = "TELEMETRI",
		el_speedTape = "PITA KECEPATAN",
		el_altTape = "KETINGGIAN",
		el_eject = "KELUAR",
		el_bottom = "KECEPATAN / KUNCI",
		el_next = "TARGET BERIKUT",
		el_pad = "PAD ARAH",
		el_radar = "RADAR",
		el_targetInfo = "INFO TARGET",
		el_boost = "BOOST",
		sec_swarm = "SWARM STRIKE",
		btn_swarm_add = "💣 TAMBAH BOM SWARM",
		btn_swarm_clear = "🗑 KOSONGKAN SWARM",
		st_swarm_max = "MAKS BOM",
		st_swarm_scatter = "WAKTU PENCAR",
		st_swarm_spread = "RADIUS PENCAR",
		st_swarm_speed = "KECEPATAN SWARM",
		st_swarm_height = "TINGGI ORBIT",
		st_swarm_radius = "RADIUS ORBIT",
		st_swarm_orbit = "KECEPATAN ORBIT",
		sw_title = "SWARM",
		sw_add = "TAMBAH +",
		sw_clear = "HAPUS",
		sw_launch = "🚀 LUNCURKAN",
		sw_orbit = "ORBIT",
		sw_launched = "MELUNCUR",
		sw_tgt = "TGT",
		sw_added = "BOM DITAMBAH",
		sw_full = "SWARM PENUH",
		sw_empty = "TIDAK ADA BOM DI ORBIT",
		sw_go = "SWARM DILUNCURKAN",
		sw_hit = "TARGET KENA",
		sw_back = "TARGET HILANG - KEMBALI",
		sw_recall = "SWARM DITARIK KEMBALI",
		sw_cleared = "SWARM DIKOSONGKAN",
		el_swarm = "PANEL SWARM",
		tab_drone = "DRONE",
		tab_drone2 = "DRONE V2",
		v2_ready = "💣 5/5 SIAP",
		v2_cleared = "💣 PILIHAN DIHAPUS",
		v2_dup = "💣 SUDAH DIPILIH",
		v2_launch = "MELUNCUR KE ATAS...",
		v2_ctrl = "KONTROL SIAP",
		tab_swarm = "SWARM",
		tab_orbit = "ORBIT",
		sec_orbit = "ORBIT TARGET",
		sec_orbit_pick = "PILIH TARGET",
		btn_orbit_attack = "💥 SERANG",
		btn_orbit_refresh = "🔄 MUAT ULANG PEMAIN",
		st_tgt_dist = "JARAK ORBIT",
		st_tgt_orbit = "KECEPATAN ORBIT",
		st_tgt_delay = "JEDA SERANG",
		or_none = "PEMAIN TIDAK ADA",
		or_set = "TARGET DIPILIH",
		or_pick = "PILIH TARGET DULU",
		or_spin = "MEMUTAR CEPAT...",
		or_busy = "SWARM SEDANG JALAN",
		tab_tornado = "TORNADO",
		sec_tornado = "TORNADO",
		st_tn_radius = "LEBAR TORNADO",
		st_tn_height = "TINGGI TORNADO",
		st_tn_speed = "KECEPATAN TORNADO",
		st_tn_delay = "JEDA SERANG",
		st_spin = "KEKUATAN PUTAR",
		tab_scatter = "SEBAR",
		sec_scatter = "SERANGAN SEBAR",
		st_sc_time = "WAKTU SEBAR",
		st_sc_dist = "JARAK SEBAR",
		st_sc_spin = "PUTARAN SEBAR",
		st_sc_speed = "KECEPATAN SERANG",
		sc_go = "BOM DISEBAR",
		sc_retry = "BELUM MELEDAK - HANTAM LAGI",
		sc_nolock = "SEBAR = TARGET ACAK",
		sc_random = "ACAK",
		sc_lost = "TARGET HILANG - TARGET BARU",
		st_n_height = "TINGGI TERBANG",
		st_n_gap = "JEDA ANTAR BOM",
		tg_cinema = "KAMERA SINEMATIK",
		tab_settings = "⚙ PENGATURAN",
		tab_visual = "🎨 VISUAL",
		sec_antilag = "ANTI-LAG",
		st_lag = "LEVEL ANTI-LAG",
		tg_autolag = "ANTI-LAG OTOMATIS",
		lag_hint = "MATI = grafik terbaik.\nRINGAN = tanpa bayangan / efek layar.\nSEDANG = + kualitas rendah, tanpa partikel map.\nTINGGI = + material polos, FPS maksimal.\nOTOMATIS menaikkan level saat FPS terus rendah.",
		sec_skin = "TEKSTUR BOM",
		sec_skin_custom = "ID TEKSTUR SENDIRI (angka saja)",
		btn_skin_apply = "PASANG KE BOM",
		skin_hint = "Tekstur dipasang ke bom yang kamu pilih atau tambahkan. Hanya kamu yang melihatnya.",
		sec_fx = "EFEK LEDAKAN",
		st_fx_size = "UKURAN LEDAKAN",
		st_fx_time = "DURASI LEDAKAN",
		st_fx_color = "WARNA LEDAKAN",
		btn_fx_preview = "▶ COBA LEDAKAN",
		fx_hint = "Hanya visual (sisi kamu). Pemain lain melihat ledakan asli game.",
		tab_fx = "💥 FX",
		tab_cinema = "🎬 SINEMA",
		sec_sound = "SUARA LEDAKAN",
		sec_sound_custom = "ID SUARA SENDIRI (angka saja)",
		st_snd_vol = "VOLUME SUARA",
		btn_snd_test = "▶ COBA SUARA",
		snd_hint = "OTOMATIS memilih suara yang cocok untuk tiap efek. KLASIK tetap pakai suara asli game. Tap paket untuk mendengarnya.",
		sec_trail = "JEJAK BOM",
		st_trail_size = "UKURAN JEJAK",
		trail_hint = "Jejak dipasang ke bom yang kamu pilih atau tambahkan. Hanya kamu yang melihatnya.",
		sec_impact = "DAMPAK",
		st_shake = "GETAR KAMERA",
		st_slow = "GERAK LAMBAT",
		impact_hint = "GERAK LAMBAT memperlambat visual dan suara ledakan, lalu kamera zoom masuk. Kamera sinematik juga menahan lebih lama. Game aslinya tidak bisa diperlambat.",
		st_swarmfx = "MODE EFEK SWARM",
		swarmfx_hint = "SAMA = efek yang kamu pilih. ACAK TIAP BOM = setiap bom swarm dapat efek acak sendiri. BERURUT = efek bergantian satu per satu.",
		sec_cinema = "KAMERA SINEMATIK",
		sec_cine_style = "GAYA KAMERA",
		tg_cinebars = "BATAS HITAM",
		st_cine_shake = "GETAR TABRAKAN",
		st_cine_dist = "JARAK SHOT",
		cine_hint = "Kamera sinematik jalan di tab SWARM / ORBIT / TORNADO / SCATTER (bukan drone). Mulai saat bom diluncurkan. ACAK memilih gaya baru untuk tiap bom.",
	},
}

function FX.L(key)
	local pack = FX.STR[Cfg.lang] or FX.STR.EN
	return pack[key] or FX.STR.EN[key] or key
end

function FX.tr(obj, key, fn)
	table.insert(FX.binds, { obj = obj, key = key, fn = fn })
	obj.Text = fn and fn() or FX.L(key)
	return obj
end

function FX.elName(id, fallback)
	local pack = FX.STR[Cfg.lang] or FX.STR.EN
	return pack["el_" .. tostring(id)] or fallback or tostring(id)
end

function FX.applyLang()
	for _, e in ipairs(FX.binds) do
		e.obj.Text = e.fn and e.fn() or FX.L(e.key)
	end

	if FX.onLang then
		FX.onLang()
	end
end

function FX.collectSettings()
	return {
		speed = K.SPEED,
		fov = Cfg.fov,
		camDist = Cfg.camDist,
		radarRange = Cfg.radarRange,
		friendCheck = Cfg.friendCheck,
		speedFx = Cfg.speedFx,
		noSignal = Cfg.noSignal,
		sens = Cfg.sens,
		boost = Cfg.boost,
		lang = Cfg.lang,
		swarmMax = Cfg.swarmMax,
		swarmScatter = Cfg.swarmScatter,
		swarmSpeed = Cfg.swarmSpeed,
		swarmHeight = Cfg.swarmHeight,
		swarmRadius = Cfg.swarmRadius,
		swarmOrbit = Cfg.swarmOrbit,
		swarmSpread = Cfg.swarmSpread,
		swarmCollapsed = Cfg.swarmCollapsed,
		tgtDist = Cfg.tgtDist,
		tgtOrbit = Cfg.tgtOrbit,
		tgtDelay = Cfg.tgtDelay,
		tnRadius = Cfg.tnRadius,
		tnHeight = Cfg.tnHeight,
		tnSpeed = Cfg.tnSpeed,
		tnDelay = Cfg.tnDelay,
		tgtHeight = Cfg.tgtHeight,
		tnLift = Cfg.tnLift,
		spinPower = Cfg.spinPower,
		scTime = Cfg.scTime,
		scDist = Cfg.scDist,
		scSpin = Cfg.scSpin,
		scSpeed = Cfg.scSpeed,
		nHeight = Cfg.nHeight,
		ver = 25,
		nGap = Cfg.nGap,
		cinema = Cfg.cinema,
		lagLevel = Cfg.lagLevel,
		autoLag = Cfg.autoLag,
		fxId = Cfg.fxId,
		fxSize = Cfg.fxSize,
		fxTime = Cfg.fxTime,
		fxColor = Cfg.fxColor,
		skinId = Cfg.skinId,
		skinCustom = Cfg.skinCustom,
		sndPack = Cfg.sndPack,
		sndVol = Cfg.sndVol,
		sndCustom = Cfg.sndCustom,
		shake = Cfg.shake,
		slowmo = Cfg.slowmo,
		trailId = Cfg.trailId,
		trailSize = Cfg.trailSize,
		swarmFx = Cfg.swarmFx,
		cineStyle = Cfg.cineStyle,
		cineBars = Cfg.cineBars,
		cineShake = Cfg.cineShake,
		cineDist = Cfg.cineDist,
	}
end

local droneActive = false
local bombFlying = false
local selectedBomb = nil
local editMode = false
local selectedId = nil

local forward = false
local backward = false
local left = false
local right = false

local yaw = 0
local pitch = 0
local targetYaw = 0
local targetPitch = 0

local cameraTouch = nil
local rightMouseDown = false

local flightStart = 0
local lastPosition = nil
local lastUpdate = os.clock()
local maxAltitude = 0

local camFocus = Vector3.zero
local camReady = false

local lockEnabled = false
local lockRoot = nil
local contacts = {}
local nextRadarScan = 0
local nextHudUpdate = 0
local messageUntil = 0
local sweepAngle = 0
local baseScale = 1

local ELEMENTS = {}
local layout = {}
local handles = {}
local dragMoved = {}
local drag = nil
local editLayer = nil

local changeSpeed, setLock, stopDrone, startDrone, showMessage, refreshLockUI
local setMenuOpen, applyElement, scheduleSave, setEditMode, selectElement, updateEditorPanel
local setStatus

do
	for _, name in ipairs({ "DroneBombSystem", "XEVRION_HUB", "DroneLockReticle", "DroneSpeedFx", "DroneNoSignal", "DroneSwarmFx", "DroneCinemaBars", "XEVRION_VERIFY" }) do
		local old = PlayerGui:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end

	for _, inst in ipairs(SoundService:GetChildren()) do
		if inst.Name == "DroneEngine" or string.sub(inst.Name, 1, 8) == "DroneUI_" then
			inst:Destroy()
		end
	end
end

local THEME = {
	Background = Color3.fromRGB(15, 17, 24),
	Panel = Color3.fromRGB(30, 34, 46),
	Track = Color3.fromRGB(42, 47, 62),
	Accent = Color3.fromRGB(70, 255, 150),
	Cyan = Color3.fromRGB(0, 210, 255),
	Danger = Color3.fromRGB(255, 85, 105),
	Warn = Color3.fromRGB(255, 190, 60),
	Text = Color3.fromRGB(240, 244, 255),
	Muted = Color3.fromRGB(140, 149, 172),
	HUD = Color3.fromRGB(120, 255, 140),
	OnBase = Color3.fromRGB(22, 64, 44),
	ErrorBase = Color3.fromRGB(70, 26, 34),
}

local HUD_GREEN = THEME.HUD
local HUD_DARK = Color3.fromRGB(4, 14, 8)

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 230, 255)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(90, 255, 140)),
	ColorSequenceKeypoint.new(0.66, Color3.fromRGB(170, 110, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 230, 255)),
})

local UI_SOUNDS = {
	Hover = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.15 },
	Click = { Id = "rbxasset://sounds/button.wav", Volume = 0.45 },
	Open = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5 },

	Close = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.3, Speed = 0.9 },
	Close2 = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.24, Speed = 0.68 },
	On = { Id = "rbxasset://sounds/switch.wav", Volume = 0.5, Speed = 1.15 },
	Off = { Id = "rbxasset://sounds/switch.wav", Volume = 0.5, Speed = 0.85 },
	Error = { Id = "rbxasset://sounds/switch.wav", Volume = 0.5, Speed = 0.6 },
}

local uiSounds = {}

for name, data in pairs(UI_SOUNDS) do
	local s = Instance.new("Sound")
	s.Name = "DroneUI_" .. name
	s.SoundId = data.Id
	s.Volume = data.Volume
	s.PlaybackSpeed = data.Speed or 1
	s.Parent = SoundService
	uiSounds[name] = s
end

local droneSound = Instance.new("Sound")
droneSound.Name = "DroneEngine"
droneSound.SoundId = "rbxassetid://9118828562"
droneSound.Looped = true
droneSound.Volume = 0.5
droneSound.Parent = SoundService

local function playUI(name)
	local s = uiSounds[name]
	if s then
		pcall(function()
			SoundService:PlayLocalSound(s)
		end)
	end

	if name == "Close" and uiSounds.Close2 then
		task.delay(0.09, function()
			pcall(function()
				SoundService:PlayLocalSound(uiSounds.Close2)
			end)
		end)
	end
end

local function tween(obj, duration, props, style, direction)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(
			duration,
			style or Enum.EasingStyle.Quint,
			direction or Enum.EasingDirection.Out
		),
		props
	)
	t:Play()
	return t
end

local function addCorner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
	return c
end

local function addStroke(obj, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

local function wrapAngle(a)
	return (a + math.pi) % (2 * math.pi) - math.pi
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

FX.Debris = game:GetService("Debris")
FX.Lighting = game:GetService("Lighting")
FX.rng = Random.new()

FX.FXLIST = {
	{ id = "classic",   en = "CLASSIC",     id_ = "KLASIK" },
	{ id = "blackhole", en = "BLACK HOLE",  id_ = "LUBANG HITAM" },
	{ id = "nuke",      en = "NUKE",        id_ = "NUKLIR" },
	{ id = "shockwave", en = "SHOCKWAVE",   id_ = "GELOMBANG KEJUT" },
	{ id = "lightning", en = "LIGHTNING",   id_ = "PETIR" },
	{ id = "frost",     en = "FROST",       id_ = "ES BEKU" },
	{ id = "fireworks", en = "FIREWORKS",   id_ = "KEMBANG API" },
	{ id = "supernova", en = "SUPERNOVA",   id_ = "SUPERNOVA" },
	{ id = "galaxy",    en = "GALAXY",      id_ = "GALAKSI" },
	{ id = "toxic",     en = "TOXIC",       id_ = "RACUN" },
	{ id = "confetti",  en = "CONFETTI",    id_ = "KONFETI" },
	{ id = "lava",      en = "LAVA",        id_ = "LAVA" },
	{ id = "glitch",    en = "GLITCH",      id_ = "GLITCH" },
	{ id = "vortex",    en = "VORTEX",      id_ = "PUSARAN" },
	{ id = "random",    en = "RANDOM",      id_ = "ACAK" },
}

FX.fxById = {}

for _, e in ipairs(FX.FXLIST) do
	FX.fxById[e.id] = e
end

FX.SKINLIST = {
	{ id = "original", en = "ORIGINAL",  id_ = "ASLI" },
	{ id = "gold",     en = "GOLD",      id_ = "EMAS" },
	{ id = "diamond",  en = "DIAMOND",   id_ = "BERLIAN" },
	{ id = "lava",     en = "LAVA",      id_ = "LAVA" },
	{ id = "ice",      en = "ICE",       id_ = "ES" },
	{ id = "cyber",    en = "CYBER",     id_ = "CYBER" },
	{ id = "rainbow",  en = "RAINBOW",   id_ = "PELANGI" },
	{ id = "army",     en = "ARMY",      id_ = "TENTARA" },
	{ id = "rust",     en = "RUSTY",     id_ = "BERKARAT" },
	{ id = "carbon",   en = "CARBON",    id_ = "KARBON" },
	{ id = "marble",   en = "MARBLE",    id_ = "MARMER" },
	{ id = "toxic",    en = "TOXIC",     id_ = "RACUN" },
	{ id = "galaxy",   en = "GALAXY",    id_ = "GALAKSI" },
	{ id = "wood",     en = "WOOD",      id_ = "KAYU" },
	{ id = "holo",     en = "HOLOGRAM",  id_ = "HOLOGRAM" },
	{ id = "custom",   en = "CUSTOM ID", id_ = "ID SENDIRI" },
}

FX.skinById = {}

for _, e in ipairs(FX.SKINLIST) do
	FX.skinById[e.id] = e
end

FX.FXCOLORS = {
	{ en = "AUTO",   id_ = "OTOMATIS", c = nil },
	{ en = "RED",    id_ = "MERAH",    c = Color3.fromRGB(255, 60, 60) },
	{ en = "ORANGE", id_ = "ORANYE",   c = Color3.fromRGB(255, 150, 40) },
	{ en = "YELLOW", id_ = "KUNING",   c = Color3.fromRGB(255, 230, 70) },
	{ en = "GREEN",  id_ = "HIJAU",    c = Color3.fromRGB(80, 255, 120) },
	{ en = "CYAN",   id_ = "CYAN",     c = Color3.fromRGB(0, 220, 255) },
	{ en = "BLUE",   id_ = "BIRU",     c = Color3.fromRGB(70, 110, 255) },
	{ en = "PURPLE", id_ = "UNGU",     c = Color3.fromRGB(170, 90, 255) },
	{ en = "PINK",   id_ = "PINK",     c = Color3.fromRGB(255, 100, 200) },
	{ en = "WHITE",  id_ = "PUTIH",    c = Color3.fromRGB(245, 245, 255) },
}

function FX.nameOf(entry)
	if Cfg.lang == "ID" then
		return entry.id_ or entry.en
	end

	return entry.en
end

FX.SNDLIST = {
	{ id = "auto",    en = "AUTO (per effect)", id_ = "OTOMATIS (per efek)" },
	{ id = "boom",    en = "BOOM",       id_ = "DENTUMAN" },
	{ id = "deep",    en = "DEEP BASS",  id_ = "BASS DALAM" },
	{ id = "thunder", en = "THUNDER",    id_ = "GUNTUR" },
	{ id = "void",    en = "VOID",       id_ = "KEHAMPAAN" },
	{ id = "glass",   en = "GLASS",      id_ = "KACA" },
	{ id = "laser",   en = "LASER",      id_ = "LASER" },
	{ id = "retro",   en = "RETRO",      id_ = "RETRO" },
	{ id = "pop",     en = "POP",        id_ = "LETUSAN" },
	{ id = "custom",  en = "CUSTOM ID",  id_ = "ID SENDIRI" },
	{ id = "off",     en = "OFF",        id_ = "MATI" },
}

FX.sndById = {}

for _, e in ipairs(FX.SNDLIST) do
	FX.sndById[e.id] = e
end

FX.TRAILLIST = {
	{ id = "none",     en = "NONE",     id_ = "TANPA" },
	{ id = "fire",     en = "FIRE",     id_ = "API" },
	{ id = "smoke",    en = "SMOKE",    id_ = "ASAP" },
	{ id = "rainbow",  en = "RAINBOW",  id_ = "PELANGI" },
	{ id = "electric", en = "ELECTRIC", id_ = "LISTRIK" },
	{ id = "ice",      en = "ICE",      id_ = "ES" },
	{ id = "galaxy",   en = "GALAXY",   id_ = "GALAKSI" },
	{ id = "toxic",    en = "TOXIC",    id_ = "RACUN" },
	{ id = "neon",     en = "NEON",     id_ = "NEON" },
	{ id = "gold",     en = "GOLD",     id_ = "EMAS" },
	{ id = "void",     en = "VOID",     id_ = "KEHAMPAAN" },
}

FX.trailById = {}

for _, e in ipairs(FX.TRAILLIST) do
	FX.trailById[e.id] = e
end

FX.CINELIST = {
	{ id = "auto",   en = "AUTO MIX",     id_ = "CAMPURAN" },
	{ id = "chase",  en = "CHASE",        id_ = "KEJAR BOM" },
	{ id = "low",    en = "LOW ANGLE",    id_ = "SUDUT RENDAH" },
	{ id = "top",    en = "TOP DOWN",     id_ = "DARI ATAS" },
	{ id = "pov",    en = "BOMB POV",     id_ = "POV BOM" },
	{ id = "side",   en = "SIDE TRACK",   id_ = "DARI SAMPING" },
	{ id = "orbit",  en = "ORBIT TARGET", id_ = "PUTAR TARGET" },
	{ id = "spiral", en = "SPIRAL",       id_ = "SPIRAL" },
	{ id = "wide",   en = "WIDE SHOT",    id_ = "JARAK JAUH" },
	{ id = "flyby",  en = "FLYBY",        id_ = "LEWAT CEPAT" },
	{ id = "random", en = "RANDOM",       id_ = "ACAK" },
}

FX.cineById = {}

for _, e in ipairs(FX.CINELIST) do
	FX.cineById[e.id] = e
end

FX.SLOW_NAMES = {
	[0] = { en = "OFF", id_ = "MATI" },
	[1] = { en = "LIGHT", id_ = "RINGAN" },
	[2] = { en = "MEDIUM", id_ = "SEDANG" },
	[3] = { en = "HEAVY", id_ = "BERAT" },
}

FX.SWFX_NAMES = {
	[0] = { en = "SAME", id_ = "SAMA" },
	[1] = { en = "RANDOM EACH", id_ = "ACAK TIAP BOM" },
	[2] = { en = "CYCLE", id_ = "BERURUT" },
}

FX.LAG = {
	saved = {},
	conn = nil,
	token = 0,
	fps = 60,
	lowFor = 0,
	cooldown = 0,
	applied = -1,
}

FX.LAG_NAMES = {
	[0] = { en = "OFF", id_ = "MATI" },
	[1] = { en = "LOW", id_ = "RINGAN" },
	[2] = { en = "MEDIUM", id_ = "SEDANG" },
	[3] = { en = "HIGH", id_ = "TINGGI" },
}

function FX.lagName(level)
	local n = FX.LAG_NAMES[level] or FX.LAG_NAMES[0]

	return FX.nameOf(n)
end

function FX.lagK()
	local lvl = Cfg.lagLevel or 0

	if lvl >= 3 then
		return 0.15
	elseif lvl == 2 then
		return 0.35
	elseif lvl == 1 then
		return 0.6
	end

	return 1
end

function FX.lagSet(inst, prop, value)
	local ok, old = pcall(function()
		return inst[prop]
	end)

	if not ok then
		return
	end

	if old == value then
		return
	end

	local set = pcall(function()
		inst[prop] = value
	end)

	if set then
		table.insert(FX.LAG.saved, { inst, prop, old })
	end
end

function FX.lagRestore()
	local L = FX.LAG

	L.token = L.token + 1

	if L.conn then
		L.conn:Disconnect()
		L.conn = nil
	end

	local list = L.saved

	L.saved = {}

	for i = #list, 1, -1 do
		local e = list[i]

		pcall(function()
			if e[2] == "__part" then
				e[1].Material = e[3][1]
				e[1].Reflectance = e[3][2]
				e[1].CastShadow = e[3][3]
			else
				e[1][e[2]] = e[3]
			end
		end)
	end

	L.applied = 0
end

function FX.isOurs(inst)
	if FX.folder and inst:IsDescendantOf(FX.folder) then
		return true
	end

	local hud = PlayerGui:FindFirstChild("XEVRION_HUB")

	if hud and inst:IsDescendantOf(hud) then
		return true
	end

	if LP.Character and inst:IsDescendantOf(LP.Character) then
		return true
	end

	return false
end

FX.HEAVY_FX = {
	ParticleEmitter = true, Trail = true, Beam = true, Fire = true,
	Smoke = true, Sparkles = true, Explosion = true,
}

function FX.lagHandle(inst, level)
	if FX.isOurs(inst) then
		return
	end

	local cls = inst.ClassName

	if level >= 2 and FX.HEAVY_FX[cls] and cls ~= "Explosion" then
		FX.lagSet(inst, "Enabled", false)
	end

	if level >= 3 then
		if inst:IsA("BasePart") then
			local n = string.lower(inst.Name)

			if not string.find(n, "bom") and not FX.skinOrig[inst] then
				table.insert(FX.LAG.saved, { inst, "__part", { inst.Material, inst.Reflectance, inst.CastShadow } })

				inst.Material = Enum.Material.SmoothPlastic
				inst.Reflectance = 0
				inst.CastShadow = false
			end
		elseif cls == "Decal" or cls == "Texture" then
			FX.lagSet(inst, "Transparency", 1)
		end
	end
end

function FX.lagApply(level)
	FX.lagRestore()

	level = level or Cfg.lagLevel or 0
	FX.LAG.applied = level

	if level <= 0 then
		return
	end

	local L = FX.LAG
	local token = L.token
	local Lighting = FX.Lighting

	FX.lagSet(Lighting, "GlobalShadows", false)
	FX.lagSet(Lighting, "EnvironmentSpecularScale", 0)

	for _, e in ipairs(Lighting:GetChildren()) do
		if e:IsA("BloomEffect") or e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect") then
			FX.lagSet(e, "Enabled", false)
		end
	end

	if level >= 2 then
		pcall(function()
			local rs = settings().Rendering
			local old = rs.QualityLevel

			rs.QualityLevel = Enum.QualityLevel.Level05

			table.insert(L.saved, { rs, "QualityLevel", old })
		end)

		local terrain = workspace:FindFirstChildOfClass("Terrain")

		if terrain then
			FX.lagSet(terrain, "Decoration", false)
			FX.lagSet(terrain, "WaterWaveSize", 0)
			FX.lagSet(terrain, "WaterReflectance", 0)
		end
	end

	if level >= 3 then
		pcall(function()
			local rs = settings().Rendering
			local old = rs.QualityLevel

			rs.QualityLevel = Enum.QualityLevel.Level01

			table.insert(L.saved, { rs, "QualityLevel", old })
		end)

		FX.lagSet(Lighting, "EnvironmentDiffuseScale", 0)
		FX.lagSet(Lighting, "Brightness", math.min(Lighting.Brightness, 2))
	end

	if level >= 2 then

		task.spawn(function()
			local n = 0

			for _, inst in ipairs(workspace:GetDescendants()) do
				if L.token ~= token then
					return
				end

				pcall(FX.lagHandle, inst, level)

				n = n + 1

				if n % 400 == 0 then
					task.wait()
				end
			end
		end)

		L.conn = workspace.DescendantAdded:Connect(function(inst)
			if L.token ~= token then
				return
			end

			task.defer(function()
				pcall(FX.lagHandle, inst, level)
			end)
		end)
	end
end

FX.fpsFrames = 0
FX.fpsT = os.clock()

FX.conn(RunService.Heartbeat, function(dt)
	FX.fpsFrames = FX.fpsFrames + 1

	local now = os.clock()

	if now - FX.fpsT >= 0.5 then
		local fps = FX.fpsFrames / (now - FX.fpsT)

		FX.fpsFrames = 0
		FX.fpsT = now
		FX.LAG.fps = fps

		if FX.fpsLabel then
			FX.fpsLabel.Text = string.format("FPS  %d", math.floor(fps + 0.5))
			FX.fpsLabel.TextColor3 = fps >= 45 and THEME.Accent or (fps >= 25 and THEME.Warn or THEME.Danger)
		end

		if Cfg.autoLag then
			if fps < 25 then
				FX.LAG.lowFor = FX.LAG.lowFor + 0.5
			else
				FX.LAG.lowFor = 0
			end

			if FX.LAG.lowFor >= 3 and now > FX.LAG.cooldown and (Cfg.lagLevel or 0) < 3 then
				FX.LAG.lowFor = 0
				FX.LAG.cooldown = now + 6
				Cfg.lagLevel = (Cfg.lagLevel or 0) + 1

				if FX.setters.lagLevel then
					FX.setters.lagLevel(Cfg.lagLevel, true)
				end

				FX.lagApply(Cfg.lagLevel)
				scheduleSave()
			end
		end
	end
end)

do

FX.folder = Instance.new("Folder")
FX.folder.Name = "XEV_FX"
FX.folder.Parent = workspace

FX.live = 0

local E = {}

FX.E = E

function E.col(default)
	local c = FX.FXCOLORS[(Cfg.fxColor or 0) + 1]

	if c and c.c then
		return c.c
	end

	return default
end

function E.hueShift(c, amount)
	local h, s, v = c:ToHSV()

	return Color3.fromHSV((h + amount) % 1, s, v)
end

function E.part(shape, color, size, cf, transp, mat)
	local p = Instance.new("Part")

	p.Shape = shape or Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.Material = mat or Enum.Material.Neon
	p.Color = color
	p.Transparency = transp or 0
	p.Size = size
	p.CFrame = cf
	p.Parent = FX.folder

	return p
end

function E.life(inst, t)
	FX.Debris:AddItem(inst, t)
end

function E.tw(obj, t, props, style, dir)
	local ok, tw = pcall(function()
		local x = TweenService:Create(obj, TweenInfo.new(
			math.max(t, 0.03),
			style or Enum.EasingStyle.Quad,
			dir or Enum.EasingDirection.Out
		), props)

		x:Play()

		return x
	end)

	return ok and tw or nil
end

function E.flash(pos, color, range, t)
	local p = E.part(Enum.PartType.Ball, color, Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos), 1)
	local l = Instance.new("PointLight")

	l.Color = color
	l.Range = range
	l.Brightness = 6
	l.Parent = p

	E.tw(l, t, { Brightness = 0, Range = 0 })
	E.life(p, t + 0.2)
end

function E.sphere(pos, color, maxSize, t, startTransp, mat, endTransp)
	local p = E.part(Enum.PartType.Ball, color, Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos), startTransp or 0.2, mat)

	E.tw(p, t, { Size = Vector3.new(maxSize, maxSize, maxSize), Transparency = endTransp or 1 })
	E.life(p, t + 0.2)

	return p
end

function E.ring(pos, color, maxSize, t, thick, tilt)
	local cf = CFrame.new(pos) * (tilt or CFrame.new()) * CFrame.Angles(0, 0, math.pi / 2)
	local p = E.part(Enum.PartType.Cylinder, color, Vector3.new(thick or 0.6, 1, 1), cf, 0.15)

	E.tw(p, t, { Size = Vector3.new(thick or 0.6, maxSize, maxSize), Transparency = 1 })
	E.life(p, t + 0.2)

	return p
end

function E.burst(pos, count, props, life)
	count = math.max(1, math.floor(count * FX.lagK() + 0.5))

	local p = E.part(Enum.PartType.Ball, Color3.new(1, 1, 1), Vector3.new(0.4, 0.4, 0.4), CFrame.new(pos), 1)
	local em = Instance.new("ParticleEmitter")

	em.Rate = 0
	em.LightEmission = 1
	em.Lifetime = NumberRange.new(0.5, 1.2)
	em.Speed = NumberRange.new(20, 40)
	em.SpreadAngle = Vector2.new(180, 180)
	em.Size = NumberSequence.new(1.5, 0)
	em.Transparency = NumberSequence.new(0, 1)

	for k, v in pairs(props or {}) do
		pcall(function()
			em[k] = v
		end)
	end

	em.Parent = p
	em:Emit(count)

	E.life(p, (life or 2) + 0.5)

	return p, em
end

local SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"
local FIRE_TEX = "rbxasset://textures/particles/fire_main.dds"

function E.rand(r)
	local v = Vector3.new(FX.rng:NextNumber(-1, 1), FX.rng:NextNumber(-1, 1), FX.rng:NextNumber(-1, 1))

	if v.Magnitude < 0.01 then
		v = Vector3.new(0, 1, 0)
	end

	return v.Unit * FX.rng:NextNumber(0.2, 1) * r
end

function E.bolt(a, b, color, thick, t)
	local segs = 6
	local prev = a
	local dir = b - a

	for i = 1, segs do
		local nextP = a + dir * (i / segs)

		if i < segs then
			nextP = nextP + E.rand(dir.Magnitude * 0.12)
		end

		local len = (nextP - prev).Magnitude

		if len > 0.05 then
			local p = E.part(
				Enum.PartType.Block,
				color,
				Vector3.new(thick, thick, len),
				CFrame.lookAt(prev, nextP) * CFrame.new(0, 0, -len / 2),
				0
			)

			E.tw(p, t, { Transparency = 1, Size = Vector3.new(0.05, 0.05, len) })
			E.life(p, t + 0.2)
		end

		prev = nextP
	end
end

local FXF = {}

FX.FXF = FXF

function FXF.classic(pos, R, T)
	local ex = Instance.new("Explosion")

	ex.Position = pos
	ex.BlastRadius = math.clamp(12 * (R / 14), 4, 100)
	ex.BlastPressure = 0
	ex.DestroyJointRadiusPercent = 0
	ex.ExplosionType = Enum.ExplosionType.NoCraters
	ex.Parent = workspace
end

function FXF.blackhole(pos, R, T)
	local k = FX.lagK()
	local purple = E.col(Color3.fromRGB(150, 70, 255))
	local orange = E.col(Color3.fromRGB(255, 140, 40))
	local grow = 0.7 * T
	local hold = 2.2 * T
	local collapse = 0.5 * T
	local total = grow + hold + collapse

	local core = E.part(Enum.PartType.Ball, Color3.new(0, 0, 0), Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos), 0, Enum.Material.SmoothPlastic)

	E.tw(core, grow, { Size = Vector3.new(R * 0.9, R * 0.9, R * 0.9) }, Enum.EasingStyle.Back)
	E.life(core, total + 0.3)

	local halo = E.part(Enum.PartType.Ball, purple, Vector3.new(0.5, 0.5, 0.5), CFrame.new(pos), 0.55)

	E.tw(halo, grow, { Size = Vector3.new(R * 1.25, R * 1.25, R * 1.25) })
	E.life(halo, total + 0.3)

	local discs = {}

	for i = 1, (k < 0.3 and 1 or 2) do
		local d = E.part(
			Enum.PartType.Cylinder,
			i == 1 and orange or purple,
			Vector3.new(0.15, 1, 1),
			CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2),
			i == 1 and 0.35 or 0.55
		)

		E.tw(d, grow, { Size = Vector3.new(0.15, R * (2.4 - (i - 1) * 0.7), R * (2.4 - (i - 1) * 0.7)) })
		E.life(d, total + 0.3)

		table.insert(discs, { part = d, tilt = (i - 1) * 0.35, dir = i == 1 and 1 or -1 })
	end

	local feed = E.part(Enum.PartType.Ball, Color3.new(1, 1, 1), Vector3.new(R * 2.6, R * 2.6, R * 2.6), CFrame.new(pos), 1)
	local em = Instance.new("ParticleEmitter")

	em.Rate = math.floor(90 * k)
	em.LightEmission = 1
	em.Color = ColorSequence.new(orange, purple)
	em.Size = NumberSequence.new(1.2, 0)
	em.Transparency = NumberSequence.new(0.1, 1)
	em.Lifetime = NumberRange.new(0.5, 0.9)
	em.Speed = NumberRange.new(-R * 2.2, -R * 1.4)

	pcall(function()
		em.Shape = Enum.ParticleEmitterShape.Sphere
		em.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		em.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	end)

	em.Parent = feed
	E.life(feed, total + 0.3)

	task.delay(grow + hold, function()
		em.Enabled = false
	end)

	local t0 = os.clock()
	local conn

	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0

		if t > grow + hold then
			conn:Disconnect()

			return
		end

		for _, d in ipairs(discs) do
			if d.part.Parent then
				d.part.CFrame = CFrame.new(pos)
					* CFrame.Angles(0, t * 5 * d.dir, 0)
					* CFrame.Angles(0.45 + d.tilt, 0, 0)
					* CFrame.Angles(0, 0, math.pi / 2)
			end
		end
	end)

	E.flash(pos, purple, R * 3, total)

	task.delay(grow + hold, function()
		pcall(function()
			E.tw(core, collapse, { Size = Vector3.new(0.3, 0.3, 0.3) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			E.tw(halo, collapse, { Size = Vector3.new(0.3, 0.3, 0.3), Transparency = 1 })

			for _, d in ipairs(discs) do
				E.tw(d.part, collapse, { Size = Vector3.new(0.15, 0.5, 0.5), Transparency = 1 })
			end
		end)
	end)

	task.delay(total, function()
		E.ring(pos, purple, R * 5, 0.8 * T, 0.5)
		E.sphere(pos, Color3.new(1, 1, 1), R * 2.5, 0.5 * T, 0.1)
		E.burst(pos, 40, { Color = ColorSequence.new(purple, orange), Speed = NumberRange.new(R, R * 3), Size = NumberSequence.new(2, 0) }, 1.5)
	end)
end

function FXF.nuke(pos, R, T)
	local orange = E.col(Color3.fromRGB(255, 130, 30))
	local yellow = E.col(Color3.fromRGB(255, 220, 90))

	E.flash(pos, yellow, R * 4, 1.2 * T)
	E.sphere(pos, Color3.new(1, 1, 1), R * 2.2, 0.35 * T, 0)
	E.sphere(pos, orange, R * 2.8, 1.1 * T, 0.1)
	E.ring(pos - Vector3.new(0, 0, 0), yellow, R * 7, 1.1 * T, 1)

	E.burst(pos, 60, {
		Texture = FIRE_TEX,
		Color = ColorSequence.new(yellow, orange),
		Speed = NumberRange.new(R * 0.6, R * 2),
		Lifetime = NumberRange.new(0.8, 1.6),
		Size = NumberSequence.new(R * 0.35, 0),
	}, 2.5)

	local steps = math.max(2, math.floor(6 * math.max(FX.lagK(), 0.4)))

	for i = 1, steps do
		task.delay((i - 1) * 0.12 * T, function()
			local h = i * R * 0.45
			local size = R * (i == steps and 2.6 or 0.9)
			local c = E.part(
				Enum.PartType.Ball,
				i == steps and orange or yellow,
				Vector3.new(size * 0.4, size * 0.4, size * 0.4),
				CFrame.new(pos + Vector3.new(0, h, 0)),
				0.25
			)

			E.tw(c, 1.2 * T, { Size = Vector3.new(size, size, size), Transparency = 1 })
			E.life(c, 1.5 * T)
		end)
	end

	E.burst(pos + Vector3.new(0, R * 2, 0), 30, {
		Texture = SMOKE_TEX,
		Color = ColorSequence.new(Color3.fromRGB(60, 50, 50), Color3.fromRGB(20, 20, 20)),
		LightEmission = 0,
		Speed = NumberRange.new(2, R * 0.8),
		Lifetime = NumberRange.new(1.5, 2.8),
		Size = NumberSequence.new(R * 0.4, R * 0.9),
	}, 3.5)
end

function FXF.shockwave(pos, R, T)
	local c = E.col(Color3.fromRGB(0, 220, 255))
	local n = math.max(2, math.floor(5 * math.max(FX.lagK(), 0.4)))

	E.flash(pos, c, R * 2, 0.8 * T)
	E.sphere(pos, c, R * 1.2, 0.3 * T, 0.2)

	for i = 1, n do
		task.delay((i - 1) * 0.1 * T, function()
			E.ring(pos, c, R * (3 + i * 1.2), 0.8 * T, 0.4)
		end)
	end

	E.ring(pos, Color3.new(1, 1, 1), R * 4, 0.6 * T, 0.3, CFrame.Angles(math.pi / 2, 0, 0))
	E.ring(pos, c, R * 4, 0.7 * T, 0.3, CFrame.Angles(0, 0, math.pi / 2))
end

function FXF.lightning(pos, R, T)
	local c = E.col(Color3.fromRGB(190, 220, 255))
	local n = math.max(3, math.floor(9 * math.max(FX.lagK(), 0.3)))

	E.flash(pos, c, R * 3, 0.6 * T)
	E.sphere(pos, Color3.new(1, 1, 1), R * 1.2, 0.25 * T, 0)

	for i = 1, n do
		task.delay((i - 1) * 0.04 * T, function()
			local top = pos + Vector3.new(FX.rng:NextNumber(-R, R), R * 4, FX.rng:NextNumber(-R, R))

			E.bolt(top, pos + E.rand(R * 0.4), c, 0.5, 0.35 * T)
		end)
	end

	for i = 1, math.max(2, math.floor(5 * FX.lagK())) do
		E.bolt(pos, pos + E.rand(R * 2), c, 0.3, 0.3 * T)
	end

	E.burst(pos, 40, { Color = ColorSequence.new(Color3.new(1, 1, 1), c), Speed = NumberRange.new(R, R * 3), Size = NumberSequence.new(0.6, 0) }, 1.5)
end

function FXF.frost(pos, R, T)
	local c = E.col(Color3.fromRGB(140, 220, 255))
	local n = math.max(4, math.floor(16 * FX.lagK()))

	E.flash(pos, c, R * 2, 0.8 * T)
	E.sphere(pos, c, R * 2.4, 0.9 * T, 0.35, Enum.Material.Ice)
	E.ring(pos, Color3.new(1, 1, 1), R * 5, 0.8 * T, 0.4)

	for i = 1, n do
		local dir = E.rand(1).Unit
		local shard = E.part(
			Enum.PartType.Block,
			c,
			Vector3.new(0.6, 0.6, R * 0.5),
			CFrame.lookAt(pos, pos + dir),
			0.1,
			Enum.Material.Ice
		)

		E.tw(shard, 1 * T, {
			CFrame = CFrame.lookAt(pos + dir * R * 2, pos + dir * R * 3),
			Transparency = 1,
		})
		E.life(shard, 1.2 * T)
	end

	E.burst(pos, 50, {
		Color = ColorSequence.new(Color3.new(1, 1, 1), c),
		Speed = NumberRange.new(R * 0.5, R * 1.6),
		Lifetime = NumberRange.new(1, 2),
		Size = NumberSequence.new(0.8, 0),
	}, 2.5)
end

function FXF.fireworks(pos, R, T)
	local n = math.max(2, math.floor(6 * math.max(FX.lagK(), 0.35)))
	local colors = {
		Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 210, 60), Color3.fromRGB(80, 255, 140),
		Color3.fromRGB(80, 180, 255), Color3.fromRGB(220, 100, 255), Color3.fromRGB(255, 255, 255),
	}

	E.flash(pos, Color3.new(1, 1, 1), R * 2, 0.5 * T)

	for i = 1, n do
		task.delay((i - 1) * 0.15 * T, function()
			local c = E.col(colors[((i - 1) % #colors) + 1])
			local at = pos + Vector3.new(FX.rng:NextNumber(-R, R), R * FX.rng:NextNumber(0.8, 2.2), FX.rng:NextNumber(-R, R))

			E.sphere(at, c, R * 0.8, 0.25 * T, 0)
			E.burst(at, 40, {
				Color = ColorSequence.new(c, Color3.new(1, 1, 1)),
				Speed = NumberRange.new(R * 0.8, R * 1.6),
				Lifetime = NumberRange.new(0.8, 1.4),
				Size = NumberSequence.new(1, 0),
				Drag = 1.5,
			}, 2)
		end)
	end
end

function FXF.supernova(pos, R, T)
	local base = E.col(Color3.fromRGB(255, 200, 120))

	E.flash(pos, Color3.new(1, 1, 1), R * 6, 1.4 * T)
	E.sphere(pos, Color3.new(1, 1, 1), R * 2, 0.4 * T, 0)

	for i = 1, math.max(2, math.floor(4 * math.max(FX.lagK(), 0.4))) do
		task.delay((i - 1) * 0.12 * T, function()
			E.sphere(pos, E.hueShift(base, i * 0.12), R * (2.5 + i * 1.4), 1.1 * T, 0.3)
			E.ring(pos, E.hueShift(base, i * 0.12), R * (5 + i * 2), 1 * T, 0.5, CFrame.Angles(i * 0.5, i * 0.3, 0))
		end)
	end

	E.burst(pos, 70, {
		Color = ColorSequence.new(Color3.new(1, 1, 1), base),
		Speed = NumberRange.new(R * 1.2, R * 4),
		Lifetime = NumberRange.new(0.8, 1.8),
		Size = NumberSequence.new(2, 0),
	}, 2.5)
end

function FXF.galaxy(pos, R, T)
	local a = E.col(Color3.fromRGB(150, 80, 255))
	local b = E.col(Color3.fromRGB(70, 160, 255))

	E.flash(pos, a, R * 3, 1.5 * T)
	E.sphere(pos, a, R * 1.6, 1 * T, 0.5)

	local rings = math.max(1, math.floor(3 * math.max(FX.lagK(), 0.4)))

	for i = 1, rings do
		E.ring(pos, i % 2 == 0 and a or b, R * (3 + i), 1.4 * T, 0.3, CFrame.Angles(i * 0.6, i * 0.4, 0))
	end

	local p, em = E.burst(pos, 120, {
		Color = ColorSequence.new(a, b),
		Speed = NumberRange.new(R * 0.4, R * 1.4),
		Lifetime = NumberRange.new(1.2, 2.4),
		Size = NumberSequence.new(1.2, 0),
		RotSpeed = NumberRange.new(-180, 180),
		Acceleration = Vector3.new(0, 4, 0),
	}, 3)
end

function FXF.toxic(pos, R, T)
	local c = E.col(Color3.fromRGB(100, 255, 80))

	E.flash(pos, c, R * 2, 1 * T)
	E.sphere(pos, c, R * 2.2, 1.4 * T, 0.5)

	E.burst(pos, 60, {
		Texture = SMOKE_TEX,
		Color = ColorSequence.new(c, Color3.fromRGB(30, 90, 30)),
		LightEmission = 0.6,
		Speed = NumberRange.new(2, R * 0.9),
		Lifetime = NumberRange.new(1.8, 3),
		Size = NumberSequence.new(R * 0.4, R * 1.1),
		Acceleration = Vector3.new(0, 5, 0),
	}, 4)

	for i = 1, math.max(3, math.floor(10 * FX.lagK())) do
		local b = E.sphere(pos + E.rand(R * 0.8), c, FX.rng:NextNumber(1, 2.5), FX.rng:NextNumber(0.8, 1.6) * T, 0.3)
	end
end

function FXF.confetti(pos, R, T)
	local n = math.max(3, math.floor(14 * FX.lagK()))
	local colors = {
		Color3.fromRGB(255, 70, 90), Color3.fromRGB(255, 210, 60), Color3.fromRGB(80, 255, 140),
		Color3.fromRGB(80, 180, 255), Color3.fromRGB(220, 100, 255),
	}

	E.flash(pos, Color3.new(1, 1, 1), R * 2, 0.5 * T)

	for i = 1, n do
		local c = E.col(colors[((i - 1) % #colors) + 1])

		E.burst(pos, 6, {
			Color = ColorSequence.new(c),
			LightEmission = 0.4,
			Speed = NumberRange.new(R * 0.8, R * 2),
			Lifetime = NumberRange.new(1.4, 2.4),
			Size = NumberSequence.new(0.7),
			Transparency = NumberSequence.new(0, 0.9),
			Acceleration = Vector3.new(0, -25, 0),
			RotSpeed = NumberRange.new(-300, 300),
			Rotation = NumberRange.new(0, 360),
		}, 3)
	end
end

function FXF.lava(pos, R, T)
	local c = E.col(Color3.fromRGB(255, 90, 20))

	E.flash(pos, c, R * 3, 1 * T)
	E.sphere(pos, c, R * 2, 0.8 * T, 0.2, Enum.Material.CrackedLava)
	E.ring(pos, c, R * 4, 0.7 * T, 0.5)

	for i = 1, math.max(3, math.floor(12 * FX.lagK())) do
		local dir = E.rand(1)
		local up = Vector3.new(dir.X, math.abs(dir.Y) + 0.8, dir.Z).Unit
		local chunk = E.part(
			Enum.PartType.Ball,
			c,
			Vector3.new(1.2, 1.2, 1.2),
			CFrame.new(pos),
			0,
			Enum.Material.CrackedLava
		)

		E.tw(chunk, 0.5 * T, { CFrame = CFrame.new(pos + up * R * 1.8) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		task.delay(0.5 * T, function()
			if chunk.Parent then
				E.tw(chunk, 0.6 * T, {
					CFrame = CFrame.new(pos + up * R * 2.4 - Vector3.new(0, R * 2, 0)),
					Transparency = 1,
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end)

		E.life(chunk, 1.4 * T)
	end

	E.burst(pos, 60, {
		Texture = FIRE_TEX,
		Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), c),
		Speed = NumberRange.new(R * 0.6, R * 2),
		Lifetime = NumberRange.new(0.8, 1.6),
		Size = NumberSequence.new(R * 0.3, 0),
		Acceleration = Vector3.new(0, -20, 0),
	}, 2.5)
end

function FXF.glitch(pos, R, T)
	local n = math.max(6, math.floor(26 * FX.lagK()))
	local colors = {
		Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 0, 200), Color3.fromRGB(80, 255, 80), Color3.fromRGB(255, 255, 255),
	}

	E.flash(pos, Color3.fromRGB(0, 255, 255), R * 2, 0.6 * T)

	for i = 1, n do
		local c = E.col(colors[((i - 1) % #colors) + 1])
		local s = FX.rng:NextNumber(0.8, 3.5)
		local at = pos + E.rand(R * 1.4)
		local cube = E.part(Enum.PartType.Block, c, Vector3.new(s, s, s), CFrame.new(at), 0)

		task.spawn(function()
			local flips = FX.rng:NextInteger(3, 7)

			for _ = 1, flips do
				if not cube.Parent then
					return
				end

				cube.Transparency = FX.rng:NextNumber(0, 0.8)
				cube.CFrame = CFrame.new(pos + E.rand(R * 1.4))
				cube.Size = Vector3.new(FX.rng:NextNumber(0.5, 4), FX.rng:NextNumber(0.5, 4), FX.rng:NextNumber(0.5, 4))

				task.wait(0.06 * T)
			end

			if cube.Parent then
				cube:Destroy()
			end
		end)

		E.life(cube, 1.5)
	end
end

function FXF.vortex(pos, R, T)
	local c = E.col(Color3.fromRGB(120, 255, 220))
	local n = math.max(3, math.floor(8 * math.max(FX.lagK(), 0.4)))

	E.flash(pos, c, R * 2.5, 1.2 * T)

	for i = 1, n do
		task.delay((i - 1) * 0.08 * T, function()
			local h = (i - 1) * R * 0.45
			local ring = E.ring(pos + Vector3.new(0, h, 0), c, R * (2 + (i % 3)), 1.1 * T, 0.4, CFrame.Angles(0, i * 0.7, 0))
		end)
	end

	E.burst(pos, 60, {
		Color = ColorSequence.new(c, Color3.new(1, 1, 1)),
		Speed = NumberRange.new(R * 0.5, R * 1.4),
		Lifetime = NumberRange.new(1, 1.8),
		Size = NumberSequence.new(1, 0),
		Acceleration = Vector3.new(0, 25, 0),
		RotSpeed = NumberRange.new(-400, 400),
	}, 2.5)
end

function FXF.light(pos, R, T)
	local c = E.col(Color3.fromRGB(255, 160, 60))

	E.sphere(pos, c, R * 1.8, 0.5 * T, 0.2)
	E.ring(pos, c, R * 3.5, 0.5 * T, 0.4)
end

local BASS = "rbxasset://sounds/bass.wav"
local COLL = "rbxasset://sounds/collide.wav"
local WATER = "rbxasset://sounds/impact_water.mp3"
local PING = "rbxasset://sounds/electronicpingshort.wav"
local SNAP = "rbxasset://sounds/snap.mp3"
local CLICK = "rbxasset://sounds/clickfast.wav"
local BUTTON = "rbxasset://sounds/button.wav"
local SWITCH = "rbxasset://sounds/switch.wav"

FX.SOUNDS = {
	boom = {
		{ id = BASS, vol = 1.6, speed = 0.55, rev = true },
		{ id = COLL, vol = 1.2, speed = 0.45, delay = 0.02 },
		{ id = WATER, vol = 0.8, speed = 0.5, delay = 0.05 },
	},
	deep = {
		{ id = BASS, vol = 2, speed = 0.3, rev = true },
		{ id = WATER, vol = 1, speed = 0.35, delay = 0.03 },
		{ id = COLL, vol = 1, speed = 0.3, delay = 0.08 },
	},
	thunder = {
		{ id = COLL, vol = 1.4, speed = 0.35, dist = true, rev = true },
		{ id = BASS, vol = 1.4, speed = 0.5, delay = 0.12 },
		{ id = WATER, vol = 1, speed = 0.6, delay = 0.3, rev = true },
	},
	void = {
		{ id = PING, vol = 0.9, speed = 0.3, speed1 = 1.8, dur = 3.4 },
		{ id = BASS, vol = 1.2, speed = 0.4, speed1 = 0.2, dur = 3.4, delay = 0.2 },
		{ id = BASS, vol = 2, speed = 0.3, delay = 3.4, rev = true },
		{ id = COLL, vol = 1.4, speed = 0.4, delay = 3.4 },
	},
	glass = {
		{ id = SNAP, vol = 1.4, speed = 1.7 },
		{ id = PING, vol = 0.8, speed = 2.2, delay = 0.05 },
		{ id = SNAP, vol = 1, speed = 2.4, delay = 0.12 },
		{ id = CLICK, vol = 1, speed = 1.8, delay = 0.2 },
	},
	laser = {
		{ id = PING, vol = 1.2, speed = 3, speed1 = 0.5, dur = 0.7 },
		{ id = CLICK, vol = 1, speed = 2, delay = 0.05 },
		{ id = BASS, vol = 1, speed = 0.8, delay = 0.3 },
	},
	retro = {
		{ id = BUTTON, vol = 1.4, speed = 0.5 },
		{ id = SWITCH, vol = 1.2, speed = 0.4, delay = 0.05 },
		{ id = PING, vol = 0.9, speed = 1.5, speed1 = 0.4, dur = 0.5, delay = 0.1 },
	},
	pop = {
		{ id = SNAP, vol = 1.4, speed = 1.1 },
		{ id = CLICK, vol = 1.2, speed = 1.4, delay = 0.08 },
		{ id = SNAP, vol = 1, speed = 1.5, delay = 0.16 },
	},
}

FX.SND_AUTO = {
	blackhole = "void", nuke = "deep", shockwave = "boom", lightning = "thunder",
	frost = "glass", fireworks = "pop", supernova = "deep", galaxy = "void",
	toxic = "boom", confetti = "pop", lava = "boom", glitch = "retro", vortex = "laser",
}

function FX.slowK()
	local l = Cfg.slowmo or 0

	if l >= 3 then
		return 3.5
	elseif l == 2 then
		return 2.4
	elseif l == 1 then
		return 1.6
	end

	return 1
end

function FX.playSound(pos, fxId, T, slow, force)
	local pack = Cfg.sndPack or "auto"

	if pack == "off" then
		return
	end

	if pack == "auto" then
		pack = FX.SND_AUTO[fxId]

		if not pack then
			return
		end
	end

	local vol = (Cfg.sndVol or 100) / 100

	if vol <= 0 then
		return
	end

	local layers

	if pack == "custom" then
		local num = string.match(tostring(Cfg.sndCustom or ""), "%d+")

		if not num then
			return
		end

		layers = { { id = "rbxassetid://" .. num, vol = 1.5, speed = 1 } }
	else
		layers = FX.SOUNDS[pack]
	end

	if not layers then
		return
	end

	local holder = E.part(Enum.PartType.Ball, Color3.new(1, 1, 1), Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos), 1)

	E.life(holder, 12)

	local slowSpeed = 1 / (1 + ((slow or 1) - 1) * 0.5)

	for _, L in ipairs(layers) do
		task.delay((L.delay or 0) * (T or 1), function()
			if not holder.Parent then
				return
			end

			local s = Instance.new("Sound")

			s.SoundId = L.id
			s.Volume = math.clamp((L.vol or 1) * vol, 0, 10)
			s.PlaybackSpeed = (L.speed or 1) * slowSpeed
			s.RollOffMode = Enum.RollOffMode.Linear
			s.RollOffMinDistance = 30
			s.RollOffMaxDistance = 450

			if L.rev then
				local r = Instance.new("ReverbSoundEffect")

				r.DecayTime = 2.5
				r.WetLevel = -4
				r.Parent = s
			end

			if L.dist then
				local d = Instance.new("DistortionSoundEffect")

				d.Level = 0.55
				d.Parent = s
			end

			s.Parent = holder
			s:Play()

			if L.speed1 then
				E.tw(s, (L.dur or 2) * (T or 1), { PlaybackSpeed = L.speed1 * slowSpeed }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end

			FX.Debris:AddItem(s, 10)
		end)
	end
end

function FX.testSound()
	local id = Cfg.fxId or "classic"

	if id == "random" or id == "classic" then
		id = "blackhole"
	end

	local cf = Camera.CFrame

	FX.playSound(cf.Position + cf.LookVector * 40, id, 1, 1, true)
end

FX.SHK = { amp = 0, t0 = -10, dur = 1, zoom = 0, zT0 = -10, zDur = 1, lastBase = nil, lastOut = nil, lastFovBase = nil, lastFovOut = nil }

function FX.impactCam(pos, R, slow)
	local sh = (Cfg.shake or 0) / 100
	local lvl = Cfg.slowmo or 0

	if sh <= 0 and lvl <= 0 then
		return
	end

	local dist = (Camera.CFrame.Position - pos).Magnitude
	local near = math.clamp(1 - dist / (120 + R * 8), 0, 1)

	if near <= 0 then
		return
	end

	local S = FX.SHK
	local now = os.clock()

	if sh > 0 then
		S.amp = math.clamp(near * sh * (R / 14) * 1.6, 0, 6)
		S.t0 = now
		S.dur = 0.9 * (slow or 1)
	end

	if lvl > 0 then
		S.zoom = lvl * 7 * near
		S.zT0 = now
		S.zDur = 1.4 * (slow or 1)
	end
end

pcall(function()
	RunService:UnbindFromRenderStep("XevrionImpactCam")
end)

RunService:BindToRenderStep("XevrionImpactCam", Enum.RenderPriority.Camera.Value + 2, function()
	local S = FX.SHK
	local now = os.clock()
	local shaking = (now - S.t0) < S.dur
	local zooming = (now - S.zT0) < S.zDur

	if not shaking and not zooming then
		S.lastOut = nil
		S.lastFovOut = nil

		return
	end

	local cm = FX.CM
	local cinema = cm and cm.state ~= "off"

	if shaking and not cinema then
		local p = (now - S.t0) / S.dur
		local k = S.amp * (1 - p) * (1 - p)

		if k > 0.005 then
			local base = Camera.CFrame

			if S.lastOut and base == S.lastOut then
				base = S.lastBase
			end

			local sx = math.noise(now * 35, 1.3, 0.2) * k
			local sy = math.noise(now * 38, 4.1, 2.7) * k
			local r = math.noise(now * 30, 7.7, 3.1) * k * 0.02

			Camera.CFrame = base * CFrame.new(sx, sy, 0) * CFrame.Angles(0, 0, r)

			S.lastBase = base
			S.lastOut = Camera.CFrame
		else
			S.lastOut = nil
		end
	else
		S.lastOut = nil
	end

	if zooming and not cinema and not droneActive then
		local p = (now - S.zT0) / S.zDur
		local env = p < 0.15 and (p / 0.15) or ((1 - (p - 0.15) / 0.85) ^ 2)
		local base = Camera.FieldOfView

		if S.lastFovOut and base == S.lastFovOut then
			base = S.lastFovBase
		end

		Camera.FieldOfView = math.clamp(base - S.zoom * env, 20, 120)

		S.lastFovBase = base
		S.lastFovOut = Camera.FieldOfView
	else
		S.lastFovOut = nil
	end
end)

FX.trailParts = {}

FX.TRAILS = {
	fire = { c0 = Color3.fromRGB(255, 230, 90), c1 = Color3.fromRGB(255, 60, 20), tex = FIRE_TEX, rate = 45, size = 2, ribbon = true, light = Color3.fromRGB(255, 120, 40) },
	smoke = { c0 = Color3.fromRGB(170, 170, 170), c1 = Color3.fromRGB(60, 60, 60), tex = SMOKE_TEX, rate = 35, size = 2.2, grow = 4, lightEm = 0 },
	rainbow = { rainbow = true, c0 = Color3.fromRGB(255, 80, 80), c1 = Color3.fromRGB(80, 120, 255), rate = 30, size = 1.2, ribbon = true },
	electric = { c0 = Color3.fromRGB(255, 255, 255), c1 = Color3.fromRGB(80, 190, 255), rate = 70, size = 0.7, fast = true, ribbon = true, light = Color3.fromRGB(120, 200, 255) },
	ice = { c0 = Color3.fromRGB(255, 255, 255), c1 = Color3.fromRGB(130, 215, 255), rate = 40, size = 1.2, ribbon = true, light = Color3.fromRGB(150, 220, 255) },
	galaxy = { c0 = Color3.fromRGB(190, 130, 255), c1 = Color3.fromRGB(60, 120, 255), rate = 50, size = 1.1, ribbon = true, light = Color3.fromRGB(150, 90, 255) },
	toxic = { c0 = Color3.fromRGB(140, 255, 70), c1 = Color3.fromRGB(30, 120, 30), tex = SMOKE_TEX, rate = 35, size = 2, light = Color3.fromRGB(110, 255, 60) },
	neon = { c0 = Color3.fromRGB(0, 255, 230), c1 = Color3.fromRGB(0, 120, 255), ribbon = true, wide = true, light = Color3.fromRGB(0, 255, 230) },
	gold = { c0 = Color3.fromRGB(255, 240, 150), c1 = Color3.fromRGB(255, 170, 30), rate = 40, size = 1, ribbon = true, light = Color3.fromRGB(255, 200, 80) },
	void = { c0 = Color3.fromRGB(150, 70, 255), c1 = Color3.fromRGB(0, 0, 0), rate = 30, size = 1.4, ribbon = true, dark = true, light = Color3.fromRGB(130, 60, 255) },
}

function FX.trailClear(p)
	for _, c in ipairs(p:GetChildren()) do
		if c.Name == "XEV_TRAIL" then
			c:Destroy()
		end
	end

	FX.trailParts[p] = nil
end

function FX.trailApply(p, id)
	if not p or not p.Parent then
		return
	end

	FX.trailClear(p)

	local def = FX.TRAILS[id]

	if not def then
		return
	end

	FX.trailParts[p] = true

	local s = math.clamp((Cfg.trailSize or 100) / 100, 0.3, 3)
	local k = FX.lagK()
	local lvl = Cfg.lagLevel or 0
	local maxDim = math.max(p.Size.X, p.Size.Y, p.Size.Z)
	local w = math.clamp(maxDim * 0.35, 0.4, 2) * s * (def.wide and 1.8 or 1)

	if def.ribbon then
		local a0 = Instance.new("Attachment")
		local a1 = Instance.new("Attachment")

		a0.Name = "XEV_TRAIL"
		a1.Name = "XEV_TRAIL"
		a0.Position = Vector3.new(0, w, 0)
		a1.Position = Vector3.new(0, -w, 0)
		a0.Parent = p
		a1.Parent = p

		local tr = Instance.new("Trail")

		tr.Name = "XEV_TRAIL"
		tr.Attachment0 = a0
		tr.Attachment1 = a1
		tr.Lifetime = (def.fast and 0.25 or 0.7) * math.max(0.5, s)
		tr.MinLength = 0.1
		tr.FaceCamera = true
		tr.LightEmission = def.dark and 0.2 or 1
		tr.Transparency = NumberSequence.new(0.05, 1)
		tr.WidthScale = NumberSequence.new(1, 0)

		if def.rainbow then
			tr.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
				ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 60)),
				ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 255, 120)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(60, 200, 255)),
				ColorSequenceKeypoint.new(0.8, Color3.fromRGB(150, 90, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 200)),
			})
		else
			tr.Color = ColorSequence.new(def.c0, def.c1)
		end

		tr.Parent = p
	end

	if def.rate and lvl < 3 then
		local em = Instance.new("ParticleEmitter")

		em.Name = "XEV_TRAIL"
		em.Rate = math.max(4, math.floor(def.rate * k * s))
		em.Lifetime = def.fast and NumberRange.new(0.12, 0.3) or NumberRange.new(0.5, 1.1)
		em.Speed = def.fast and NumberRange.new(10, 26) or NumberRange.new(0, 3)
		em.SpreadAngle = Vector2.new(180, 180)
		em.LightEmission = def.lightEm or 0.9
		em.Size = NumberSequence.new(def.size * s, (def.grow or 0) * s)
		em.Transparency = NumberSequence.new(0.1, 1)
		em.RotSpeed = NumberRange.new(-120, 120)
		em.Color = ColorSequence.new(def.c0, def.c1)

		if def.tex then
			em.Texture = def.tex
		end

		if id == "ice" then
			em.Acceleration = Vector3.new(0, -8, 0)
		elseif id == "fire" or id == "toxic" then
			em.Acceleration = Vector3.new(0, 6, 0)
		end

		em.Parent = p
	end

	if def.light and lvl < 3 then
		local l = Instance.new("PointLight")

		l.Name = "XEV_TRAIL"
		l.Color = def.light
		l.Range = 10 * s
		l.Brightness = 1.2
		l.Parent = p
	end
end

function FX.trailApplyAll()
	local id = Cfg.trailId or "none"
	local list = {}
	local seen = {}

	local function add(p)
		if p and p.Parent and not seen[p] then
			seen[p] = true
			table.insert(list, p)
		end
	end

	for p in pairs(FX.trailParts) do
		add(p)
	end

	add(selectedBomb)

	for _, b in ipairs(SW.bombs) do
		add(b.part)
	end

	for _, p in ipairs(list) do
		FX.trailApply(p, id)
	end
end

FX.trailT = 0

FX.conn(RunService.Heartbeat, function(dt)
	FX.trailT = FX.trailT + dt

	if FX.trailT < 0.5 then
		return
	end

	FX.trailT = 0

	for p in pairs(FX.trailParts) do
		if not p.Parent then
			FX.trailParts[p] = nil
		end
	end

	local id = Cfg.trailId

	if not id or id == "none" then
		return
	end

	if selectedBomb and selectedBomb.Parent and not FX.trailParts[selectedBomb] then
		FX.trailApply(selectedBomb, id)
	end

	for _, b in ipairs(SW.bombs) do
		if b.part and b.part.Parent and not FX.trailParts[b.part] then
			FX.trailApply(b.part, id)
		end
	end
end)

function FX.boom(pos, swarm)
	local id = Cfg.fxId or "classic"
	local mode = Cfg.swarmFx or 0

	local function pool()
		local list = {}

		for _, e in ipairs(FX.FXLIST) do
			if e.id ~= "random" and e.id ~= "classic" then
				table.insert(list, e.id)
			end
		end

		return list
	end

	if swarm and mode == 1 then
		local list = pool()

		id = list[FX.rng:NextInteger(1, #list)]
	elseif swarm and mode == 2 then
		local list = pool()

		FX.cycle = ((FX.cycle or 0) % #list) + 1
		id = list[FX.cycle]
	elseif id == "random" then
		local list = pool()

		id = list[FX.rng:NextInteger(1, #list)]
	end

	local fn = FXF[id] or FXF.classic
	local slow = FX.slowK()
	local R = 14 * math.clamp((Cfg.fxSize or 100) / 100, 0.25, 4)
	local T = math.clamp((Cfg.fxTime or 100) / 100, 0.3, 3) * slow

	local lvl = Cfg.lagLevel or 0
	local limit = (lvl >= 3 and 2) or (lvl == 2 and 3) or (lvl == 1 and 5) or 8

	if id ~= "classic" and FX.live >= limit then
		fn = FXF.light
	end

	FX.live = FX.live + 1

	task.delay(math.min(5 * T + 1, 14), function()
		FX.live = math.max(0, FX.live - 1)
	end)

	local ok, err = pcall(fn, pos, R, T)

	if not ok then
		warn("[XEVRION HUB] explosion effect error: " .. tostring(err))
		pcall(FXF.classic, pos, R, T)
	end

	pcall(FX.playSound, pos, id, T, slow)
	pcall(FX.impactCam, pos, R, slow)
end

function FX.previewBoom()
	local cf = Camera.CFrame
	local R = 14 * math.clamp((Cfg.fxSize or 100) / 100, 0.25, 4)
	local pos = cf.Position + cf.LookVector * (R * 2 + 18)

	FX.boom(pos)
end

FX.skinOrig = setmetatable({}, { __mode = "k" })
FX.skinParts = {}
FX.skinMark = "XEV_SKIN"

FX.SKINS = {
	gold = { color = Color3.fromRGB(255, 200, 40), mat = Enum.Material.Metal, refl = 0.35, glow = Color3.fromRGB(255, 210, 90), spark = Color3.fromRGB(255, 230, 120) },
	diamond = { color = Color3.fromRGB(130, 230, 255), mat = Enum.Material.Glass, refl = 0.45, trans = 0.2, glow = Color3.fromRGB(150, 240, 255), spark = Color3.fromRGB(255, 255, 255) },
	lava = { color = Color3.fromRGB(255, 90, 20), mat = Enum.Material.CrackedLava, glow = Color3.fromRGB(255, 110, 30), fire = true },
	ice = { color = Color3.fromRGB(170, 225, 255), mat = Enum.Material.Ice, refl = 0.2, glow = Color3.fromRGB(150, 220, 255), spark = Color3.fromRGB(230, 250, 255) },
	cyber = { color = Color3.fromRGB(0, 255, 230), mat = Enum.Material.Neon, glow = Color3.fromRGB(0, 255, 230), trail = Color3.fromRGB(0, 255, 230) },
	rainbow = { color = Color3.fromRGB(255, 0, 0), mat = Enum.Material.Neon, rainbow = true, trail = Color3.fromRGB(255, 255, 255) },
	army = { color = Color3.fromRGB(70, 90, 50), mat = Enum.Material.Fabric },
	rust = { color = Color3.fromRGB(150, 85, 45), mat = Enum.Material.CorrodedMetal },
	carbon = { color = Color3.fromRGB(25, 25, 30), mat = Enum.Material.DiamondPlate, refl = 0.1 },
	marble = { color = Color3.fromRGB(235, 235, 240), mat = Enum.Material.Marble, refl = 0.1 },
	toxic = { color = Color3.fromRGB(110, 255, 60), mat = Enum.Material.Neon, glow = Color3.fromRGB(110, 255, 60), smoke = Color3.fromRGB(90, 220, 60) },
	galaxy = { color = Color3.fromRGB(110, 60, 220), mat = Enum.Material.ForceField, glow = Color3.fromRGB(150, 80, 255), spark = Color3.fromRGB(180, 140, 255), trail = Color3.fromRGB(150, 80, 255) },
	wood = { color = Color3.fromRGB(140, 95, 55), mat = Enum.Material.WoodPlanks },
	holo = { color = Color3.fromRGB(80, 200, 255), mat = Enum.Material.ForceField, trans = 0.3, glow = Color3.fromRGB(80, 200, 255) },
}

function FX.skinTargets(part)
	local list = { part }
	local parent = part.Parent

	if parent and parent ~= workspace and (parent:IsA("Model") or parent:IsA("Tool")) then
		local n = string.lower(parent.Name)

		if string.find(n, "bom") and not parent:FindFirstChildOfClass("Humanoid") then
			list = {}

			for _, d in ipairs(parent:GetDescendants()) do
				if d:IsA("BasePart") and #list < 40 then
					table.insert(list, d)
				end
			end

			if #list == 0 then
				list = { part }
			end
		end
	end

	return list
end

function FX.skinClear(p)
	local o = FX.skinOrig[p]

	for _, c in ipairs(p:GetChildren()) do
		if c.Name == FX.skinMark then
			c:Destroy()
		end
	end

	if o then
		pcall(function()
			p.Color = o.Color
			p.Material = o.Material
			p.Reflectance = o.Reflectance
			p.Transparency = o.Transparency

			if o.TextureID ~= nil then
				p.TextureID = o.TextureID
			end
		end)

		FX.skinOrig[p] = nil
	end

	FX.skinParts[p] = nil
end

function FX.skinMarkInst(inst, parent)
	inst.Name = FX.skinMark
	inst.Parent = parent

	return inst
end

function FX.skinApply(part, id)
	if not part or not part.Parent then
		return
	end

	for _, p in ipairs(FX.skinTargets(part)) do

		FX.skinClear(p)

		if id ~= "original" then
			local def = FX.SKINS[id]

			local o = {
				Color = p.Color,
				Material = p.Material,
				Reflectance = p.Reflectance,
				Transparency = p.Transparency,
			}

			if p:IsA("MeshPart") then
				o.TextureID = p.TextureID
			end

			FX.skinOrig[p] = o
			FX.skinParts[p] = true

			if id == "custom" then
				local raw = tostring(Cfg.skinCustom or "")
				local num = string.match(raw, "%d+")

				if num then
					local url = "rbxassetid://" .. num

					if p:IsA("MeshPart") then
						pcall(function()
							p.TextureID = url
						end)
					end

					for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
						local tx = Instance.new("Texture")

						tx.Texture = url
						tx.Face = face
						tx.StudsPerTileU = 2
						tx.StudsPerTileV = 2
						FX.skinMarkInst(tx, p)
					end
				end
			elseif def then
				p.Color = def.color
				p.Material = def.mat
				p.Reflectance = def.refl or 0

				if def.trans then

					p.Transparency = math.max(o.Transparency, def.trans)
				end

				if def.glow then
					local l = Instance.new("PointLight")

					l.Color = def.glow
					l.Range = 12
					l.Brightness = 1.5
					FX.skinMarkInst(l, p)
				end

				local k = FX.lagK()

				if (def.spark or def.fire or def.smoke) and k > 0.2 then
					local em = Instance.new("ParticleEmitter")

					em.Rate = math.floor(14 * k)
					em.Lifetime = NumberRange.new(0.4, 0.9)
					em.Speed = NumberRange.new(1, 4)
					em.SpreadAngle = Vector2.new(180, 180)
					em.LightEmission = 0.8
					em.Size = NumberSequence.new(0.9, 0)
					em.Transparency = NumberSequence.new(0.2, 1)

					if def.fire then
						em.Texture = FIRE_TEX
						em.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 80, 20))
						em.Acceleration = Vector3.new(0, 6, 0)
					elseif def.smoke then
						em.Texture = SMOKE_TEX
						em.Color = ColorSequence.new(def.smoke)
						em.LightEmission = 0.4
						em.Size = NumberSequence.new(1.6, 3)
					else
						em.Color = ColorSequence.new(def.spark)
					end

					FX.skinMarkInst(em, p)
				end

				if def.trail then
					local a0 = Instance.new("Attachment")
					local a1 = Instance.new("Attachment")

					a0.Position = Vector3.new(0, p.Size.Y * 0.4, 0)
					a1.Position = Vector3.new(0, -p.Size.Y * 0.4, 0)

					FX.skinMarkInst(a0, p)
					FX.skinMarkInst(a1, p)

					local tr = Instance.new("Trail")

					tr.Attachment0 = a0
					tr.Attachment1 = a1
					tr.Lifetime = 0.5
					tr.LightEmission = 1
					tr.Color = ColorSequence.new(def.trail)
					tr.Transparency = NumberSequence.new(0.1, 1)
					FX.skinMarkInst(tr, p)
				end
			end
		end
	end
end

function FX.skinApplyAll()
	local id = Cfg.skinId or "original"
	local list = {}
	local seen = {}

	local function add(p)
		if p and p.Parent and not seen[p] then
			seen[p] = true
			table.insert(list, p)
		end
	end

	for p in pairs(FX.skinParts) do
		add(p)
	end

	add(selectedBomb)

	for _, b in ipairs(SW.bombs) do
		add(b.part)
	end

	local done = {}

	for _, p in ipairs(list) do
		if not done[p] then
			for _, t in ipairs(FX.skinTargets(p)) do
				done[t] = true
			end

			FX.skinApply(p, id)
		end
	end
end

FX.skinT = 0

FX.conn(RunService.Heartbeat, function(dt)
	FX.skinT = FX.skinT + dt

	if FX.skinT < 0.5 then
		return
	end

	FX.skinT = 0

	for p in pairs(FX.skinParts) do
		if not p.Parent then
			FX.skinParts[p] = nil
		end
	end

	local id = Cfg.skinId

	if id == "original" then
		return
	end

	if selectedBomb and selectedBomb.Parent and not FX.skinParts[selectedBomb] then
		FX.skinApply(selectedBomb, id)
	end

	for _, b in ipairs(SW.bombs) do
		if b.part and b.part.Parent and not FX.skinParts[b.part] then
			FX.skinApply(b.part, id)
		end
	end
end)

FX.conn(RunService.Heartbeat, function()
	if Cfg.skinId ~= "rainbow" then
		return
	end

	local hue = (os.clock() * 0.4) % 1

	for p in pairs(FX.skinParts) do
		if p.Parent then
			p.Color = Color3.fromHSV(hue, 1, 1)
		else
			FX.skinParts[p] = nil
		end
	end
end)

end

local gui = Instance.new("ScreenGui")
gui.Name = "XEVRION_HUB"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local function getViewport()
	local s = gui.AbsoluteSize
	if s.X < 1 or s.Y < 1 then
		return Camera.ViewportSize
	end
	return s
end

local function scaleOf(id)
	local L = layout[id]
	if L then
		return L.s
	end
	return DEFAULT_SCALE[id] or 1
end

local function register(id, name, frame, setScale)
	if not setScale then
		local sc = frame:FindFirstChild("LayoutScale")
		if not sc then
			sc = Instance.new("UIScale")
			sc.Name = "LayoutScale"
			sc.Parent = frame
		end
		setScale = function(s)
			sc.Scale = s
		end
	end

	ELEMENTS[id] = {
		name = name,
		frame = frame,
		anchor = frame.AnchorPoint,
		defPos = frame.Position,
		setScale = setScale,
	}
end

function applyElement(id)
	local e = ELEMENTS[id]
	if not e then
		return
	end

	local L = layout[id]

	if L then
		e.frame.Position = UDim2.fromScale(L.x, L.y)
	else
		e.frame.Position = e.defPos
	end

	e.setScale(scaleOf(id))
end

local function applyAll()
	for id in pairs(ELEMENTS) do
		applyElement(id)
	end
	updateEditorPanel()
end

local function ensureLayout(id)
	if layout[id] then
		return layout[id]
	end

	local e = ELEMENTS[id]
	local origin = editLayer.AbsolutePosition
	local vp = editLayer.AbsoluteSize
	local p = e.frame.AbsolutePosition - origin + e.frame.AbsoluteSize * e.anchor

	layout[id] = {
		x = math.clamp(p.X / math.max(vp.X, 1), 0, 1),
		y = math.clamp(p.Y / math.max(vp.Y, 1), 0, 1),
		s = scaleOf(id),
	}

	return layout[id]
end

local function beginDrag(id, input)
	local L = ensureLayout(id)

	-- FIX4: while the 3D preview is open the menu is shown at a clamped spot, so
	-- start the drag from that real spot (not from the stale saved one)
	if id == "menu" and FX.pvSyncDrag then
		pcall(FX.pvSyncDrag, L)
	end

	dragMoved[id] = false

	drag = {
		id = id,
		input = input,
		start = Vector2.new(input.Position.X, input.Position.Y),
		x0 = L.x,
		y0 = L.y,
		moved = false,
	}
end

FX.conn(UIS.InputChanged, function(input)
	if not drag then
		return
	end

	local isMouse = drag.input.UserInputType == Enum.UserInputType.MouseButton1

	if input ~= drag.input
		and not (isMouse and input.UserInputType == Enum.UserInputType.MouseMovement) then
		return
	end

	local d = Vector2.new(input.Position.X, input.Position.Y) - drag.start

	if not drag.moved then
		if d.Magnitude < 4 then
			return
		end

		drag.moved = true
		dragMoved[drag.id] = true
	end

	local vp = getViewport()
	local L = layout[drag.id]

	L.x = math.clamp(drag.x0 + d.X / vp.X, 0, 1)
	L.y = math.clamp(drag.y0 + d.Y / vp.Y, 0, 1)

	applyElement(drag.id)
end)

FX.conn(UIS.InputEnded, function(input)
	if not drag then
		return
	end

	local isMouse = drag.input.UserInputType == Enum.UserInputType.MouseButton1

	if input == drag.input or (isMouse and input.UserInputType == Enum.UserInputType.MouseButton1) then
		if drag.moved then
			scheduleSave()
		end

		drag = nil
	end
end)

function Store.write(text)
	local saved = false

	if type(writefile) == "function" then
		local ok, err = pcall(writefile, Store.FILE, text)

		if ok then
			saved = true
		else
			warn("[XEVRION HUB] writefile failed: " .. tostring(err))
		end
	end

	local okLs = pcall(function()
		local store = game:GetService("LocalStorageService")
		store:SetItem(Store.KEY, text)
		store:Flush()
	end)

	return saved or okLs
end

function Store.read()
	if type(readfile) == "function" and type(isfile) == "function" then
		local okExists, exists = pcall(isfile, Store.FILE)

		if okExists and exists then
			local okRead, raw = pcall(readfile, Store.FILE)

			if okRead and type(raw) == "string" and raw ~= "" then
				return raw, "file"
			end
		end
	end

	local okLs, raw = pcall(function()
		return game:GetService("LocalStorageService"):GetItem(Store.KEY)
	end)

	if okLs and type(raw) == "string" and raw ~= "" then
		return raw, "LocalStorageService"
	end

	return nil, nil
end

function scheduleSave()
	Store.dirty = true

	if Store.queued then
		return
	end

	Store.queued = true

	task.delay(0.4, function()
		Store.queued = false

		local payload = {}
		local count = 0

		for id, L in pairs(layout) do
			payload[id] = { x = L.x, y = L.y, s = L.s }
			count += 1
		end

		payload._settings = FX.collectSettings()

		local okJson, json = pcall(function()
			return game:GetService("HttpService"):JSONEncode(payload)
		end)

		if not okJson then
			warn("[XEVRION HUB] could not encode layout: " .. tostring(json))
			return
		end

		if Store.write(json) then
		else
			warn("[XEVRION HUB] save failed: no storage available")
		end
	end)
end

local toggle = Instance.new("TextButton")
toggle.Name = "Toggle"
toggle.Size = UDim2.fromOffset(58, 58)
toggle.AnchorPoint = Vector2.new(0.5, 0.5)
toggle.Position = UDim2.fromOffset(15 + 29, 15 + 29)
toggle.BackgroundColor3 = THEME.Background
toggle.BorderSizePixel = 0
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.ZIndex = 200
toggle.Parent = gui

addCorner(toggle, 18)

local toggleGradient = Instance.new("UIGradient")
toggleGradient.Color = RAINBOW
toggleGradient.Parent = addStroke(toggle, Color3.new(1, 1, 1), 2.5, 0)

local toggleScale = Instance.new("UIScale")
toggleScale.Parent = toggle

local toggleIcon = Instance.new("ImageLabel")
toggleIcon.Name = "Logo"
toggleIcon.Size = UDim2.fromScale(0.72, 0.72)
toggleIcon.AnchorPoint = Vector2.new(0.5, 0.5)
toggleIcon.Position = UDim2.fromScale(0.5, 0.5)
toggleIcon.BackgroundTransparency = 1
toggleIcon.Image = "rbxassetid://124298982787093"
toggleIcon.ScaleType = Enum.ScaleType.Fit
toggleIcon.ImageColor3 = Color3.fromRGB(200, 205, 220)
toggleIcon.ZIndex = 201
toggleIcon.Parent = toggle

register("toggle", "TOGGLE", toggle, function(s)
	toggle.Size = UDim2.fromOffset(58 * s, 58 * s)
end)

local menu = Instance.new("CanvasGroup")
menu.Name = "Menu"
menu.Size = UDim2.fromOffset(K.MENU_W, K.MENU_H)
menu.Position = UDim2.fromOffset(15, 85)
menu.BackgroundColor3 = Color3.fromRGB(60, 62, 72)
menu.BorderSizePixel = 0
menu.Active = true
menu.GroupTransparency = 1
menu.ZIndex = 200
menu.Parent = gui

addCorner(menu, 18)

local menuGradient = Instance.new("UIGradient")
menuGradient.Color = ColorSequence.new(Color3.fromRGB(16, 16, 22))
menuGradient.Parent = addStroke(menu, Color3.new(1, 1, 1), 4, 0)

local menuScale = Instance.new("UIScale")
menuScale.Parent = menu

FX.hdr = {}

do
	local DARK = Color3.fromRGB(18, 18, 24)

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 48)
	header.BackgroundColor3 = Color3.new(1, 1, 1)
	header.BorderSizePixel = 0
	header.Active = true
	header.Parent = menu

	local headerGradient = Instance.new("UIGradient")
	headerGradient.Color = ColorSequence.new(Color3.fromRGB(255, 228, 118), Color3.fromRGB(245, 178, 46))
	headerGradient.Rotation = 90
	headerGradient.Parent = header

	local shine = Instance.new("Frame")
	shine.Size = UDim2.new(1, 0, 0.5, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.8
	shine.BorderSizePixel = 0
	shine.Parent = header

	local headerLine = Instance.new("Frame")
	headerLine.Size = UDim2.new(1, 0, 0, 3)
	headerLine.Position = UDim2.new(0, 0, 1, -3)
	headerLine.BackgroundColor3 = DARK
	headerLine.BorderSizePixel = 0
	headerLine.Parent = header

	local headerLogo = Instance.new("ImageLabel")
	headerLogo.Name = "HeaderLogo"
	headerLogo.Size = UDim2.fromOffset(32, 32)
	headerLogo.Position = UDim2.fromOffset(10, 7)
	headerLogo.BackgroundTransparency = 1
	headerLogo.Image = toggleIcon.Image
	headerLogo.ScaleType = Enum.ScaleType.Fit
	headerLogo.Parent = header

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "HeaderTitle"
	titleLabel.Size = UDim2.fromOffset(150, 30)
	titleLabel.Position = UDim2.fromOffset(48, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "XEVRION HUB"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextSize = 19
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header

	local titleStroke = addStroke(titleLabel, DARK, 2, 0)
	titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

	local betaBadge = Instance.new("Frame")
	betaBadge.Name = "BetaBadge"
	betaBadge.Size = UDim2.fromOffset(40, 16)
	betaBadge.Position = UDim2.fromOffset(48 + 126, 15)
	betaBadge.BackgroundColor3 = Color3.fromRGB(232, 52, 84)
	betaBadge.BorderSizePixel = 0
	betaBadge.Parent = header

	addCorner(betaBadge, 6)
	addStroke(betaBadge, DARK, 2, 0)

	local betaGradient = Instance.new("UIGradient")
	betaGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200))
	betaGradient.Rotation = 90
	betaGradient.Parent = betaBadge

	local betaText = Instance.new("TextLabel")
	betaText.Size = UDim2.fromScale(1, 1)
	betaText.BackgroundTransparency = 1
	betaText.Text = "BETA"
	betaText.TextColor3 = Color3.new(1, 1, 1)
	betaText.TextSize = 11
	betaText.Font = Enum.Font.FredokaOne
	betaText.Parent = betaBadge

	local betaStroke = addStroke(betaText, Color3.fromRGB(110, 14, 34), 1.2, 0)
	betaStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

	local function placeBeta()
		betaBadge.Position = UDim2.fromOffset(48 + titleLabel.TextBounds.X + 6, 15)
	end

	titleLabel:GetPropertyChangedSignal("TextBounds"):Connect(placeBeta)
	placeBeta()

	local statusPill = Instance.new("Frame")
	statusPill.Name = "StatusPill"
	statusPill.Size = UDim2.fromOffset(78, 22)
	statusPill.Position = UDim2.new(1, -132, 0, 13)
	statusPill.BackgroundColor3 = Color3.fromRGB(36, 38, 46)
	statusPill.BorderSizePixel = 0
	statusPill.Parent = header

	addCorner(statusPill, 11)
	addStroke(statusPill, DARK, 2, 0)

	local statusDot = Instance.new("Frame")
	statusDot.Size = UDim2.fromOffset(8, 8)
	statusDot.Position = UDim2.fromOffset(9, 7)
	statusDot.BackgroundColor3 = THEME.Danger
	statusDot.BorderSizePixel = 0
	statusDot.Parent = statusPill

	addCorner(statusDot, 4)

	TweenService:Create(
		statusDot,
		TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ BackgroundTransparency = 0.6 }
	):Play()

	local statusText = Instance.new("TextLabel")
	statusText.Size = UDim2.new(1, -24, 1, 0)
	statusText.Position = UDim2.fromOffset(22, 0)
	statusText.BackgroundTransparency = 1
	statusText.Text = FX.L("standby")
	statusText.TextColor3 = THEME.Muted
	statusText.TextSize = 10
	statusText.Font = Enum.Font.GothamBold
	statusText.TextXAlignment = Enum.TextXAlignment.Left
	statusText.Parent = statusPill

	function setStatus(active)
		FX.statusActive = active
		statusText.Text = active and FX.L("active") or FX.L("standby")

		tween(statusDot, 0.25, {
			BackgroundColor3 = active and THEME.Accent or THEME.Danger,
		})

		tween(statusText, 0.25, {
			TextColor3 = active and THEME.Accent or THEME.Muted,
		})
	end

	local function headerButton(text, base, fromRight)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(30, 30)
		b.Position = UDim2.new(1, -(fromRight + 30), 0, 8)
		b.BackgroundColor3 = base
		b.BorderSizePixel = 0
		b.AutoButtonColor = false
		b.Text = text
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextSize = 20
		b.Font = Enum.Font.FredokaOne
		b.Parent = header

		addCorner(b, 8)
		addStroke(b, DARK, 2, 0)

		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200))
		g.Rotation = 90
		g.Parent = b

		local ts = addStroke(b, DARK, 1.5, 0)
		ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

		b.MouseEnter:Connect(function()
			playUI("Hover")
			tween(b, 0.15, { BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.2) })
		end)

		b.MouseLeave:Connect(function()
			tween(b, 0.2, { BackgroundColor3 = base })
		end)

		b.MouseButton1Down:Connect(function()
			tween(b, 0.08, { BackgroundColor3 = base:Lerp(Color3.new(0, 0, 0), 0.25) })
		end)

		b.MouseButton1Up:Connect(function()
			tween(b, 0.2, { BackgroundColor3 = base })
		end)

		return b
	end

	local closeButton = headerButton("X", Color3.fromRGB(232, 52, 84), 8)

	closeButton.Activated:Connect(function()
		setMenuOpen(false)
	end)

	local backButton = headerButton("<", Color3.fromRGB(52, 128, 238), 44)

	backButton.Visible = false

	header.InputBegan:Connect(function(input)
		if isPress(input) then
			beginDrag("menu", input)
		end
	end)

	FX.hdr.title = titleLabel
	FX.hdr.back = backButton
	FX.hdr.pill = statusPill
end

do
	local inset = Instance.new("Frame")
	inset.Name = "Inset"
	inset.Position = UDim2.fromOffset(8, 54)
	inset.Size = UDim2.new(1, -16, 1, -70)
	inset.BackgroundColor3 = Color3.fromRGB(38, 40, 48)
	inset.BorderSizePixel = 0
	inset.Parent = menu

	addCorner(inset, 10)
	addStroke(inset, Color3.fromRGB(20, 21, 27), 2, 0)
end

do
	local bar = Instance.new("Frame")
	bar.Name = "ResizeBar"
	bar.Size = UDim2.new(1, 0, 0, 18)
	bar.Position = UDim2.new(0, 0, 1, -18)
	bar.BackgroundTransparency = 1
	bar.Active = true
	bar.Parent = menu

	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromOffset(64, 5)
	pill.AnchorPoint = Vector2.new(0.5, 0.5)
	pill.Position = UDim2.new(0.5, 0, 0.5, 1)
	pill.BackgroundColor3 = Color3.fromRGB(24, 25, 31)
	pill.BorderSizePixel = 0
	pill.Parent = bar

	addCorner(pill, 3)

	local resize = nil

	bar.MouseEnter:Connect(function()
		tween(pill, 0.15, { BackgroundColor3 = Color3.fromRGB(246, 192, 72) })
	end)

	bar.MouseLeave:Connect(function()
		if not resize then
			tween(pill, 0.2, { BackgroundColor3 = Color3.fromRGB(24, 25, 31) })
		end
	end)

	bar.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end

		local L = ensureLayout("menu")

		resize = {
			input = input,
			y0 = input.Position.Y,
			s0 = L.s,
			h0 = K.MENU_H * baseScale * L.s,
		}

		tween(pill, 0.1, { BackgroundColor3 = Color3.fromRGB(246, 192, 72) })
	end)

	FX.conn(UIS.InputChanged, function(input)
		if not resize then
			return
		end

		local isMouse = resize.input.UserInputType == Enum.UserInputType.MouseButton1

		if input ~= resize.input
			and not (isMouse and input.UserInputType == Enum.UserInputType.MouseMovement) then
			return
		end

		local dy = input.Position.Y - resize.y0
		local vp = getViewport()
		local pos = menu.AbsolutePosition

		local maxFit = math.min(
			(vp.X - pos.X - 6) / (K.MENU_W * baseScale),
			(vp.Y - pos.Y - 6) / (K.MENU_H * baseScale)
		)

		local hi = math.max(K.MIN_LAYOUT_SCALE, math.min(K.MAX_LAYOUT_SCALE, maxFit))
		local newScale = resize.s0 * math.max(resize.h0 + dy, 20) / resize.h0

		local L = layout.menu

		if L then
			L.s = math.clamp(newScale, K.MIN_LAYOUT_SCALE, hi)
			applyElement("menu")
		end
	end)

	FX.conn(UIS.InputEnded, function(input)
		if not resize then
			return
		end

		local isMouse = resize.input.UserInputType == Enum.UserInputType.MouseButton1

		if input == resize.input or (isMouse and input.UserInputType == Enum.UserInputType.MouseButton1) then
			resize = nil

			tween(pill, 0.2, { BackgroundColor3 = Color3.fromRGB(24, 25, 31) })
			scheduleSave()
		end
	end)
end

local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.Position = UDim2.fromOffset(8, 54)
body.Size = UDim2.new(1, -16, 1, -70)
body.CanvasSize = UDim2.new(0, 0, 0, 0)
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.ScrollingDirection = Enum.ScrollingDirection.Y
body.ScrollBarThickness = 3
body.ScrollBarImageColor3 = THEME.Cyan
body.Parent = menu

do
	local bodyPadding = Instance.new("UIPadding")
	bodyPadding.PaddingTop = UDim.new(0, 12)
	bodyPadding.PaddingBottom = UDim.new(0, 14)
	bodyPadding.PaddingLeft = UDim.new(0, 14)
	bodyPadding.PaddingRight = UDim.new(0, 14)
	bodyPadding.Parent = body

	local bodyList = Instance.new("UIListLayout")
	bodyList.Padding = UDim.new(0, 8)
	bodyList.SortOrder = Enum.SortOrder.LayoutOrder
	bodyList.Parent = body
end

FX.cardNames = {
	[1] = "DRONE", [10] = "DRONE V2", [2] = "SWARM", [3] = "ORBIT", [4] = "TORNADO",
	[5] = "SCATTER", [6] = "SETTINGS", [7] = "VISUAL", [8] = "FX", [9] = "CINEMA",
}

do
	local DARK = Color3.fromRGB(18, 18, 24)

	local CARDS = {
		{ "DRONE", 1, "113554023524711", Color3.fromRGB(236, 138, 62) },
		{ "DRONE V2", 10, "92882079488570", Color3.fromRGB(96, 116, 196) },
		{ "SWARM", 2, "96160552813005", Color3.fromRGB(246, 192, 72) },
		{ "ORBIT", 3, "108242074073890", Color3.fromRGB(216, 58, 78) },
		{ "TORNADO", 4, "132490362958555", Color3.fromRGB(46, 46, 60) },
		{ "SCATTER", 5, "111320966041139", Color3.fromRGB(74, 196, 88) },
		{ "SETTINGS", 6, "78512744723975", Color3.fromRGB(96, 116, 196) },
		{ "VISUAL", 7, "128511237858988", Color3.fromRGB(236, 138, 62) },
		{ "FX", 8, "77663140897875", Color3.fromRGB(216, 58, 78) },
		{ "CINEMA", 9, "105910009975098", Color3.fromRGB(246, 192, 72) },
	}

	local PAD, GAP, COLS, CH = 8, 6, 5, 110
	local pageW = K.MENU_W - 16
	local CW = (pageW - PAD * 2 - GAP * (COLS - 1)) / COLS
	local rows = math.ceil(#CARDS / COLS)

	local grid = Instance.new("ScrollingFrame")
	grid.Name = "ShopGrid"
	grid.Position = UDim2.fromOffset(8, 54)
	grid.Size = UDim2.new(1, -16, 1, -70)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.CanvasSize = UDim2.fromOffset(0, PAD * 2 + rows * CH + (rows - 1) * GAP)
	grid.ScrollingDirection = Enum.ScrollingDirection.Y
	grid.ScrollBarThickness = 3
	grid.ScrollBarImageColor3 = Color3.fromRGB(246, 192, 72)
	grid.Parent = menu

	for i, data in ipairs(CARDS) do
		local name, tab, assetId, tileColor = data[1], data[2], data[3], data[4]
		local col = (i - 1) % COLS
		local row = math.floor((i - 1) / COLS)

		local card = Instance.new("TextButton")
		card.Name = "Card_" .. name
		card.Position = UDim2.fromOffset(PAD + col * (CW + GAP), PAD + row * (CH + GAP))
		card.Size = UDim2.fromOffset(CW, CH)
		card.BackgroundColor3 = Color3.fromRGB(28, 29, 36)
		card.BorderSizePixel = 0
		card.AutoButtonColor = false
		card.Text = ""
		card.Parent = grid

		addCorner(card, 10)
		addStroke(card, DARK, 2, 0)

		local cardScale = Instance.new("UIScale")
		cardScale.Parent = card

		local tile = Instance.new("Frame")
		tile.Size = UDim2.fromOffset(60, 60)
		tile.Position = UDim2.fromOffset((CW - 60) / 2, 5)
		tile.BackgroundColor3 = tileColor
		tile.BorderSizePixel = 0
		tile.Parent = card

		addCorner(tile, 9)
		addStroke(tile, tileColor:Lerp(Color3.new(0, 0, 0), 0.5), 2, 0)

		local tileGradient = Instance.new("UIGradient")
		tileGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205))
		tileGradient.Rotation = 90
		tileGradient.Parent = tile

		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.fromScale(0.86, 0.86)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.Image = "rbxassetid://" .. assetId
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Parent = tile

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -4, 0, 14)
		nameLabel.Position = UDim2.fromOffset(2, 67)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = name
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextSize = 13
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.Parent = card

		local openBox = Instance.new("Frame")
		openBox.Size = UDim2.new(1, -12, 0, 18)
		openBox.Position = UDim2.fromOffset(6, 86)
		openBox.BackgroundColor3 = Color3.fromRGB(84, 206, 62)
		openBox.BorderSizePixel = 0
		openBox.Parent = card

		addCorner(openBox, 6)
		addStroke(openBox, Color3.fromRGB(34, 98, 30), 2, 0)

		local openGradient = Instance.new("UIGradient")
		openGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 224, 196))
		openGradient.Rotation = 90
		openGradient.Parent = openBox

		local openLabel = Instance.new("TextLabel")
		openLabel.Size = UDim2.fromScale(1, 1)
		openLabel.BackgroundTransparency = 1
		openLabel.Text = "OPEN"
		openLabel.TextColor3 = Color3.new(1, 1, 1)
		openLabel.TextSize = 12
		openLabel.Font = Enum.Font.FredokaOne
		openLabel.Parent = openBox

		local openStroke = addStroke(openLabel, Color3.fromRGB(34, 98, 30), 1.5, 0)
		openStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

		card.MouseEnter:Connect(function()
			playUI("Hover")
			tween(card, 0.15, { BackgroundColor3 = Color3.fromRGB(40, 42, 52) })
		end)

		card.MouseLeave:Connect(function()
			tween(card, 0.2, { BackgroundColor3 = Color3.fromRGB(28, 29, 36) })
			tween(cardScale, 0.15, { Scale = 1 })
		end)

		card.MouseButton1Down:Connect(function()
			tween(cardScale, 0.08, { Scale = 0.94 })
		end)

		card.MouseButton1Up:Connect(function()
			tween(cardScale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)

		card.Activated:Connect(function()
			playUI("Click")
			FX.openTab(tab)
		end)
	end

	FX.hdr.grid = grid
end

FX.page = "grid"

function FX.showPage(page)
	FX.page = page

	local h = FX.hdr

	h.grid.Visible = (page == "grid")
	body.Visible = (page == "menu")
	h.back.Visible = (page == "menu")

	if page == "menu" then
		h.title.Text = FX.cardNames[FX.tab] or "MENU"
		h.pill.Position = UDim2.new(1, -176, 0, 13)
	else
		h.title.Text = "XEVRION HUB"
		h.pill.Position = UDim2.new(1, -132, 0, 13)
	end

	body.CanvasPosition = Vector2.new(0, 0)
end

function FX.openTab(i)
	if FX.tab ~= i or (i == 10 and not FX.V2.on) then
		FX.setTab(i)
	else
		FX.applyTab()
	end

	FX.showPage("menu")
end

do

	FX.hdr.back.Activated:Connect(function()
		playUI("Click")

		if FX.V2.on then
			FX.V2.on = false

			if FX.V2.leave then
				FX.V2.leave()
			end
		end

		FX.showPage("grid")
	end)

	FX.showPage("grid")
end

local function createSectionLabel(text, order)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 14)
	l.BackgroundTransparency = 1
	if type(text) == "table" then
		FX.tr(l, text.key)
	else
		l.Text = text
	end
	l.TextColor3 = THEME.Muted
	l.TextSize = 11
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = order
	l.Parent = body
	return l
end

local buttonStyles = {}

local SHOP = {
	Dark = Color3.fromRGB(18, 18, 24),
	Blue = Color3.fromRGB(52, 128, 238),
	Green = Color3.fromRGB(84, 206, 62),
	Red = Color3.fromRGB(232, 52, 84),
	Gold = Color3.fromRGB(246, 192, 72),
}

local function shopColorOf(base, accent)
	if base == THEME.OnBase then
		return SHOP.Green
	elseif base == THEME.ErrorBase then
		return SHOP.Red
	elseif accent == THEME.Warn then
		return SHOP.Gold
	end

	return SHOP.Blue
end

local function shopEdge(color)
	return color:Lerp(Color3.new(0, 0, 0), 0.6)
end

local function applyButtonStyle(button, base, accent)
	local style = buttonStyles[button]

	if not style then
		return
	end

	local color = shopColorOf(base, accent)
	local edge = shopEdge(color)

	style.Base = color

	tween(button, 0.25, { BackgroundColor3 = color })
	tween(style.Stroke, 0.25, { Color = edge })
	tween(style.TextStroke, 0.25, { Color = edge })

	if style.Mirror and buttonStyles[style.Mirror] then
		applyButtonStyle(style.Mirror, base, accent)
	end
end

local function createButton(text, parent)
	local b = Instance.new("TextButton")

	b.Size = UDim2.new(1, 0, 0, 42)
	b.BackgroundColor3 = SHOP.Blue
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	if type(text) == "table" then
		FX.tr(b, text.key)
	else
		b.Text = text
	end
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 14
	b.Font = Enum.Font.FredokaOne
	b.Parent = parent

	addCorner(b, 10)

	local edge = shopEdge(SHOP.Blue)

	local s = addStroke(b, edge, 2, 0)

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205))
	grad.Rotation = 90
	grad.Parent = b

	local ts = addStroke(b, edge, 1.5, 0)
	ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

	local sc = Instance.new("UIScale")
	sc.Parent = b

	local style = {
		Base = SHOP.Blue,
		Stroke = s,
		TextStroke = ts,
	}

	buttonStyles[b] = style

	b.MouseEnter:Connect(function()
		playUI("Hover")
		tween(b, 0.15, { BackgroundColor3 = style.Base:Lerp(Color3.new(1, 1, 1), 0.15) })
	end)

	b.MouseLeave:Connect(function()
		tween(b, 0.2, { BackgroundColor3 = style.Base })
		tween(sc, 0.15, { Scale = 1 })
	end)

	b.MouseButton1Down:Connect(function()
		tween(sc, 0.08, { Scale = 0.95 })
		tween(b, 0.08, { BackgroundColor3 = style.Base:Lerp(Color3.new(0, 0, 0), 0.2) })
	end)

	b.MouseButton1Up:Connect(function()
		tween(sc, 0.2, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween(b, 0.2, { BackgroundColor3 = style.Base:Lerp(Color3.new(1, 1, 1), 0.15) })
	end)

	b.Activated:Connect(function()
		playUI("Click")
	end)

	return b
end

function FX.stepper(label, min, max, step, value, fmt, order, onChange)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 42)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = body

	local minus = createButton("−", row)
	minus.Size = UDim2.new(0, 52, 1, 0)
	minus.TextSize = 22

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -116, 1, 0)
	holder.Position = UDim2.fromOffset(58, 0)
	holder.BackgroundColor3 = THEME.Background
	holder.BorderSizePixel = 0
	holder.Parent = row

	addCorner(holder, 12)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 14)
	title.Position = UDim2.fromOffset(0, 5)
	title.BackgroundTransparency = 1
	FX.tr(title, label)
	title.TextColor3 = THEME.Muted
	title.TextSize = 10
	title.Font = Enum.Font.GothamBold
	title.Parent = holder

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, 0, 0, 18)
	valueLabel.Position = UDim2.fromOffset(0, 19)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextColor3 = THEME.Accent
	valueLabel.TextSize = 15
	valueLabel.Font = Enum.Font.GothamBlack
	valueLabel.Parent = holder

	local plus = createButton("+", row)
	plus.Size = UDim2.new(0, 52, 1, 0)
	plus.Position = UDim2.new(1, -52, 0, 0)
	plus.TextSize = 22

	local current = value

	local function setValue(v, silent)
		v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
		current = v
		valueLabel.Text = fmt(v)

		if not silent then
			onChange(v)
		end

		return v
	end

	minus.Activated:Connect(function()
		setValue(current - step)
	end)

	plus.Activated:Connect(function()
		setValue(current + step)
	end)

	setValue(value, true)

	return setValue
end

function FX.toggle(key, label, order)
	local b = createButton("", body)
	b.Size = UDim2.new(1, 0, 0, 36)
	b.LayoutOrder = order

	local function refresh()
		local on = Cfg[key]

		b.Text = FX.L(label) .. (on and ": ON" or ": OFF")

		if on then
			applyButtonStyle(b, THEME.OnBase, THEME.Accent, 0.3)
		else
			applyButtonStyle(b, THEME.Panel, THEME.Cyan, 0.75)
		end
	end

	FX.toggleList = FX.toggleList or {}

	local list = FX.toggleList[key]

	if not list then
		list = {}
		FX.toggleList[key] = list
	end

	table.insert(list, refresh)

	b.Activated:Connect(function()
		Cfg[key] = not Cfg[key]

		for _, r in ipairs(list) do
			r()
		end

		scheduleSave()
	end)

	refresh()

	FX.togglers[key] = function()
		for _, r in ipairs(list) do
			r()
		end
	end
end

FX.tab = 1
FX.tabButtons = {}

function FX.tabOf(order)
	if order == 0 then
		return 0
	end

	if order <= 21 or order == 99 then
		return 1
	end

	if order <= 39 then
		return 2
	end

	if order <= 59 then
		return 3
	end

	if order <= 79 then
		return 4
	end

	if order <= 98 then
		return 5
	end

	if order <= 139 then
		return 6
	end

	if order <= 179 then
		return 7
	end

	if order <= 219 then
		return 8
	end

	return 9
end

function FX.applyTab()
	for _, child in ipairs(body:GetChildren()) do
		if child:IsA("GuiObject") then
			local t = FX.tabOf(child.LayoutOrder)

			child.Visible = (t == 0 and child.Name ~= "Tabs") or (t == FX.tab) or (FX.tab == 10 and t == 1)
		end
	end

	for i, b in ipairs(FX.tabButtons) do
		if i == FX.tab then
			applyButtonStyle(b, THEME.OnBase, THEME.Accent, 0.3)
		else
			applyButtonStyle(b, THEME.Panel, THEME.Cyan, 0.75)
		end
	end

	body.CanvasPosition = Vector2.new(0, 0)
end

function FX.setTab(i)
	local wasV2 = FX.V2.on

	FX.tab = i
	FX.applyTab()

	FX.V2.on = (i == 10)

	if wasV2 and i ~= 10 and FX.V2.leave then
		FX.V2.leave()
	elseif i == 10 and not wasV2 and FX.V2.enter then
		FX.V2.enter()
	end

	if i <= 5 or i == 10 then
		SW.wantMode = (i == 3 and "orbit") or (i == 4 and "tornado") or (i == 5 and "scatter") or "swarm"
	end

	if SW.syncMode then
		SW.syncMode()
	end

	if i >= 3 and i <= 5 and SW.buildList then
		SW.buildList()
	end
end

do
	local bar = Instance.new("Frame")
	bar.Name = "Tabs"
	bar.Size = UDim2.new(1, 0, 0, 74)
	bar.BackgroundTransparency = 1
	bar.LayoutOrder = 0
	bar.Parent = body

	local row1 = { [1] = 0, [10] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5 }

	for i, key in ipairs({ "tab_drone", "tab_swarm", "tab_orbit", "tab_tornado", "tab_scatter", "tab_settings", "tab_visual", "tab_fx", "tab_cinema", "tab_drone2" }) do
		local b = createButton({ key = key }, bar)

		if row1[i] then
			local slot = row1[i]

			b.Size = UDim2.new(1 / 6, -4, 0, 34)
			b.Position = UDim2.new(slot / 6, slot, 0, 0)
			b.TextScaled = true

			local lim1 = Instance.new("UITextSizeConstraint")

			lim1.MaxTextSize = 9
			lim1.MinTextSize = 5
			lim1.Parent = b
		else

			b.Size = UDim2.new(0.25, -3, 0, 34)
			b.Position = UDim2.new((i - 6) / 4, i - 6, 0, 40)
			b.TextScaled = true

			local lim = Instance.new("UITextSizeConstraint")

			lim.MaxTextSize = 10
			lim.MinTextSize = 6
			lim.Parent = b
		end

		b.Activated:Connect(function()
			if FX.tab ~= i then
				FX.setTab(i)
			end
		end)

		FX.tabButtons[i] = b
	end
end

createSectionLabel({ key = "sec_target" }, 1)

local bombButton = createButton(FX.L("btn_bomb"), body)
bombButton.LayoutOrder = 2

createSectionLabel({ key = "sec_flight" }, 3)

local droneButton = createButton(FX.L("btn_drone_off"), body)
droneButton.LayoutOrder = 4

do
	local editButton = createButton({ key = "btn_edit" }, body)
	editButton.LayoutOrder = 110

	editButton.Activated:Connect(function()
		if droneActive then
			return
		end

		setEditMode(true)
	end)
end

local speedRow = Instance.new("Frame")
speedRow.Size = UDim2.new(1, 0, 0, 42)
speedRow.BackgroundTransparency = 1
speedRow.LayoutOrder = 6
speedRow.Parent = body

local speedDown = createButton("−", speedRow)
speedDown.Size = UDim2.new(0, 52, 1, 0)
speedDown.TextSize = 22

local speedLabel

do
	local speedLabelHolder = Instance.new("Frame")
	speedLabelHolder.Size = UDim2.new(1, -116, 1, 0)
	speedLabelHolder.Position = UDim2.fromOffset(58, 0)
	speedLabelHolder.BackgroundColor3 = THEME.Background
	speedLabelHolder.BorderSizePixel = 0
	speedLabelHolder.Parent = speedRow

	addCorner(speedLabelHolder, 12)

	speedLabel = Instance.new("TextLabel")
	speedLabel.Size = UDim2.fromScale(1, 1)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = FX.L("speed") .. " " .. K.SPEED
	speedLabel.TextColor3 = THEME.Accent
	speedLabel.TextSize = 15
	speedLabel.Font = Enum.Font.GothamBlack
	speedLabel.Parent = speedLabelHolder
end

local speedUp = createButton("+", speedRow)
speedUp.Size = UDim2.new(0, 52, 1, 0)
speedUp.Position = UDim2.new(1, -52, 0, 0)
speedUp.TextSize = 22

local menuSpeedFill

do
	local speedTrack = Instance.new("Frame")
	speedTrack.Size = UDim2.new(1, 0, 0, 6)
	speedTrack.BackgroundColor3 = THEME.Track
	speedTrack.BorderSizePixel = 0
	speedTrack.LayoutOrder = 7
	speedTrack.Parent = body

	addCorner(speedTrack, 3)

	menuSpeedFill = Instance.new("Frame")
	menuSpeedFill.Size = UDim2.new(math.clamp(K.SPEED / K.MAX_SPEED, 0, 1), 0, 1, 0)
	menuSpeedFill.BackgroundColor3 = Color3.new(1, 1, 1)
	menuSpeedFill.BorderSizePixel = 0
	menuSpeedFill.Parent = speedTrack

	addCorner(menuSpeedFill, 3)

	local menuSpeedGradient = Instance.new("UIGradient")
	menuSpeedGradient.Color = ColorSequence.new(THEME.Cyan, THEME.Accent)
	menuSpeedGradient.Parent = menuSpeedFill
end

createSectionLabel({ key = "sec_lockfilter" }, 8)
FX.toggle("friendCheck", "tg_friend", 10)

createSectionLabel({ key = "sec_camera" }, 12)

FX.setters.fov = FX.stepper("st_fov", 40, 110, 5, Cfg.fov, function(v)
	return string.format("%d°", v)
end, 13, function(v)
	Cfg.fov = v
	scheduleSave()
end)

FX.setters.camDist = FX.stepper("st_camdist", 10, 60, 5, Cfg.camDist, function(v)
	return string.format("%d st", v)
end, 14, function(v)
	Cfg.camDist = v
	scheduleSave()
end)

FX.setters.sens = FX.stepper("st_sens", 20, 300, 10, Cfg.sens, function(v)
	return string.format("%d%%", v)
end, 15, function(v)
	Cfg.sens = v
	scheduleSave()
end)

FX.setters.boost = FX.stepper("st_boost", 125, 400, 25, Cfg.boost, function(v)
	return string.format("%d%%", v)
end, 16, function(v)
	Cfg.boost = v
	scheduleSave()
end)

FX.toggle("speedFx", "tg_speedfx", 17)
FX.toggle("noSignal", "tg_nosignal", 18)

createSectionLabel({ key = "sec_language" }, 100)

do
	local langRow = Instance.new("Frame")
	langRow.Size = UDim2.new(1, 0, 0, 42)
	langRow.BackgroundTransparency = 1
	langRow.LayoutOrder = 101
	langRow.Parent = body

	local enButton = createButton("ENGLISH", langRow)
	enButton.Size = UDim2.new(0.5, -4, 1, 0)

	local idButton = createButton("INDONESIA", langRow)
	idButton.Size = UDim2.new(0.5, -4, 1, 0)
	idButton.Position = UDim2.new(0.5, 4, 0, 0)

	local function paint(button, on)
		if on then
			applyButtonStyle(button, THEME.OnBase, THEME.Accent, 0.3)
		else
			applyButtonStyle(button, THEME.Panel, THEME.Cyan, 0.75)
		end
	end

	function FX.paintLang()
		paint(enButton, Cfg.lang == "EN")
		paint(idButton, Cfg.lang == "ID")
	end

	local function pick(code)
		if Cfg.lang == code then
			return
		end

		Cfg.lang = code
		FX.applyLang()
		scheduleSave()
	end

	enButton.Activated:Connect(function()
		pick("EN")
	end)

	idButton.Activated:Connect(function()
		pick("ID")
	end)

	FX.paintLang()
end

function FX.grid(order, list, getSel, onPick, refreshName)
	local frame = Instance.new("Frame")

	frame.BackgroundTransparency = 1
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, 0, 0, math.ceil(#list / 2) * 38 - 4)
	frame.Parent = body

	local gl = Instance.new("UIGridLayout")

	gl.CellSize = UDim2.new(0.5, -3, 0, 34)
	gl.CellPadding = UDim2.fromOffset(6, 4)
	gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.Parent = frame

	local buttons = {}

	for i, entry in ipairs(list) do
		local b = createButton("", frame)

		b.LayoutOrder = i
		b.TextSize = 11
		b.TextWrapped = true

		b.Activated:Connect(function()
			onPick(entry.id)
		end)

		buttons[i] = b
	end

	local function refresh()
		local sel = getSel()

		for i, entry in ipairs(list) do
			local b = buttons[i]

			b.Text = FX.nameOf(entry)

			if entry.id == sel then
				applyButtonStyle(b, THEME.OnBase, THEME.Accent, 0.3)
			else
				applyButtonStyle(b, THEME.Panel, THEME.Cyan, 0.75)
			end
		end
	end

	FX.togglers[refreshName] = refresh
	refresh()

	return frame
end

function FX.noteLabel(key, order, height)
	local l = Instance.new("TextLabel")

	l.Size = UDim2.new(1, 0, 0, height or 40)
	l.BackgroundTransparency = 1
	FX.tr(l, key)
	l.TextColor3 = THEME.Muted
	l.TextSize = 10
	l.Font = Enum.Font.GothamMedium
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.LayoutOrder = order
	l.Parent = body

	return l
end

do
	createSectionLabel({ key = "sec_antilag" }, 102)

	local fps = Instance.new("TextLabel")

	fps.Size = UDim2.new(1, 0, 0, 22)
	fps.BackgroundColor3 = THEME.Background
	fps.BorderSizePixel = 0
	fps.Text = "FPS  --"
	fps.TextColor3 = THEME.Accent
	fps.TextSize = 14
	fps.Font = Enum.Font.GothamBlack
	fps.LayoutOrder = 103
	fps.Parent = body

	addCorner(fps, 8)

	FX.fpsLabel = fps

	FX.setters.lagLevel = FX.stepper("st_lag", 0, 3, 1, Cfg.lagLevel, function(v)
		return FX.lagName(v)
	end, 104, function(v)
		Cfg.lagLevel = v
		FX.lagApply(v)
		FX.skinApplyAll()
		FX.trailApplyAll()
		scheduleSave()
	end)

	FX.toggle("autoLag", "tg_autolag", 105)

	FX.noteLabel("lag_hint", 106, 92)

	createSectionLabel("DELETE SCRIPT", 120)

	function FX.deleteScript()
		pcall(function()
			if FX.pvForceLeave then
				FX.pvForceLeave()
			end
		end)

		pcall(function()
			stopDrone()
		end)

		pcall(function()
			if SW.recall then
				SW.recall()
			end
		end)

		FX.dead = true

		for _, c in ipairs(FX.conns) do
			pcall(function()
				c:Disconnect()
			end)
		end

		pcall(function()
			RunService:UnbindFromRenderStep("XevrionImpactCam")
		end)

		pcall(function()
			RunService:UnbindFromRenderStep("XevrionCinema")
		end)

		pcall(function()
			UIS.MouseBehavior = Enum.MouseBehavior.Default
		end)

		pcall(function()
			local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")

			Camera.CameraType = Enum.CameraType.Custom

			if hum then
				Camera.CameraSubject = hum
			end
		end)

		for _, name in ipairs({ "DroneBombSystem", "XEVRION_HUB", "DroneLockReticle", "DroneSpeedFx", "DroneNoSignal", "DroneSwarmFx", "DroneCinemaBars", "XEVRION_VERIFY" }) do
			local old = PlayerGui:FindFirstChild(name)

			if old then
				pcall(function()
					old:Destroy()
				end)
			end
		end

		for _, inst in ipairs(SoundService:GetChildren()) do
			if inst.Name == "DroneEngine" or string.sub(inst.Name, 1, 8) == "DroneUI_" then
				pcall(function()
					inst:Destroy()
				end)
			end
		end

		pcall(function()
			FX.folder:Destroy()
		end)

		pcall(function()
			gui:Destroy()
		end)
	end

	local deleteButton = createButton("DELETE SCRIPT", body)
	deleteButton.LayoutOrder = 121
	deleteButton.Size = UDim2.new(1, 0, 0, 40)

	applyButtonStyle(deleteButton, THEME.ErrorBase, THEME.Danger, 0.3)

	local armToken = 0

	deleteButton.Activated:Connect(function()
		if armToken == 0 then
			armToken = os.clock()

			local mine = armToken

			deleteButton.Text = "TAP AGAIN TO CONFIRM"

			task.delay(4, function()
				if armToken == mine and deleteButton.Parent then
					armToken = 0
					deleteButton.Text = "DELETE SCRIPT"
				end
			end)

			return
		end

		FX.deleteScript()
	end)
end

do

	createSectionLabel({ key = "sec_skin" }, 140)

	FX.grid(141, FX.SKINLIST, function()
		return Cfg.skinId
	end, function(id)
		if Cfg.skinId == id then
			return
		end

		Cfg.skinId = id
		FX.togglers.skinGrid()
		FX.skinApplyAll()
		scheduleSave()
	end, "skinGrid")

	createSectionLabel({ key = "sec_skin_custom" }, 142)

	local boxRow = Instance.new("Frame")

	boxRow.Size = UDim2.new(1, 0, 0, 38)
	boxRow.BackgroundColor3 = THEME.Background
	boxRow.BorderSizePixel = 0
	boxRow.LayoutOrder = 143
	boxRow.Parent = body

	addCorner(boxRow, 12)
	addStroke(boxRow, SHOP.Dark, 2, 0)

	local box = Instance.new("TextBox")

	box.Size = UDim2.new(1, -16, 1, 0)
	box.Position = UDim2.fromOffset(8, 0)
	box.BackgroundTransparency = 1
	box.Text = Cfg.skinCustom or ""
	box.PlaceholderText = "123456789"
	box.PlaceholderColor3 = THEME.Muted
	box.TextColor3 = THEME.Text
	box.TextSize = 13
	box.Font = Enum.Font.GothamBold
	box.ClearTextOnFocus = false
	box.Parent = boxRow

	box.FocusLost:Connect(function()
		Cfg.skinCustom = string.match(box.Text, "%d+") or ""
		box.Text = Cfg.skinCustom

		scheduleSave()

		if Cfg.skinId == "custom" then
			FX.skinApplyAll()
		end
	end)

	FX.togglers.skinBox = function()
		box.Text = Cfg.skinCustom or ""
	end

	local applyBtn = createButton({ key = "btn_skin_apply" }, body)

	applyBtn.Size = UDim2.new(1, 0, 0, 36)
	applyBtn.LayoutOrder = 144

	applyBtn.Activated:Connect(function()
		FX.skinApplyAll()
	end)

	FX.noteLabel("skin_hint", 145, 40)

	createSectionLabel({ key = "sec_fx" }, 150)

	FX.grid(151, FX.FXLIST, function()
		return Cfg.fxId
	end, function(id)
		Cfg.fxId = id
		FX.togglers.fxGrid()
		scheduleSave()
	end, "fxGrid")

	FX.setters.fxSize = FX.stepper("st_fx_size", 25, 400, 25, Cfg.fxSize, function(v)
		return string.format("%d%%", v)
	end, 152, function(v)
		Cfg.fxSize = v
		scheduleSave()
	end)

	FX.setters.fxTime = FX.stepper("st_fx_time", 50, 300, 25, Cfg.fxTime, function(v)
		return string.format("%d%%", v)
	end, 153, function(v)
		Cfg.fxTime = v
		scheduleSave()
	end)

	FX.setters.fxColor = FX.stepper("st_fx_color", 0, #FX.FXCOLORS - 1, 1, Cfg.fxColor, function(v)
		return FX.nameOf(FX.FXCOLORS[v + 1])
	end, 154, function(v)
		Cfg.fxColor = v
		scheduleSave()
	end)

	local previewBtn = createButton({ key = "btn_fx_preview" }, body)

	previewBtn.LayoutOrder = 155

	previewBtn.Activated:Connect(function()
		FX.boom(Camera.CFrame.Position + Camera.CFrame.LookVector * (14 * math.clamp((Cfg.fxSize or 100) / 100, 0.25, 4) * 2 + 18))
	end)

	FX.noteLabel("fx_hint", 156, 40)

	FX.togglers.visualWords = function()
		FX.setters.lagLevel(Cfg.lagLevel, true)
		FX.setters.fxColor(Cfg.fxColor, true)
	end
end

function FX.idBox(order, get, set)
	local row = Instance.new("Frame")

	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundColor3 = THEME.Background
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = body

	addCorner(row, 12)
	addStroke(row, SHOP.Dark, 2, 0)

	local box = Instance.new("TextBox")

	box.Size = UDim2.new(1, -16, 1, 0)
	box.Position = UDim2.fromOffset(8, 0)
	box.BackgroundTransparency = 1
	box.Text = get() or ""
	box.PlaceholderText = "123456789"
	box.PlaceholderColor3 = THEME.Muted
	box.TextColor3 = THEME.Text
	box.TextSize = 13
	box.Font = Enum.Font.GothamBold
	box.ClearTextOnFocus = false
	box.Parent = row

	box.FocusLost:Connect(function()
		local v = string.match(box.Text, "%d+") or ""

		box.Text = v
		set(v)
	end)

	return function()
		box.Text = get() or ""
	end
end

do
	FX.setters.swarmFx = FX.stepper("st_swarmfx", 0, 2, 1, Cfg.swarmFx, function(v)
		return FX.nameOf(FX.SWFX_NAMES[v] or FX.SWFX_NAMES[0])
	end, 157, function(v)
		Cfg.swarmFx = v
		scheduleSave()
	end)

	FX.noteLabel("swarmfx_hint", 158, 52)
end

do

	createSectionLabel({ key = "sec_sound" }, 180)

	FX.grid(181, FX.SNDLIST, function()
		return Cfg.sndPack
	end, function(id)
		Cfg.sndPack = id
		FX.togglers.sndGrid()
		scheduleSave()
		FX.testSound()
	end, "sndGrid")

	createSectionLabel({ key = "sec_sound_custom" }, 182)

	FX.togglers.sndBox = FX.idBox(183, function()
		return Cfg.sndCustom
	end, function(v)
		Cfg.sndCustom = v
		scheduleSave()

		if Cfg.sndPack == "custom" then
			FX.testSound()
		end
	end)

	FX.setters.sndVol = FX.stepper("st_snd_vol", 0, 300, 25, Cfg.sndVol, function(v)
		return string.format("%d%%", v)
	end, 184, function(v)
		Cfg.sndVol = v
		scheduleSave()
	end)

	local testBtn = createButton({ key = "btn_snd_test" }, body)

	testBtn.Size = UDim2.new(1, 0, 0, 36)
	testBtn.LayoutOrder = 185

	testBtn.Activated:Connect(function()
		FX.testSound()
	end)

	FX.noteLabel("snd_hint", 186, 52)

	createSectionLabel({ key = "sec_trail" }, 190)

	FX.grid(191, FX.TRAILLIST, function()
		return Cfg.trailId
	end, function(id)
		if Cfg.trailId == id then
			return
		end

		Cfg.trailId = id
		FX.togglers.trailGrid()
		FX.trailApplyAll()
		scheduleSave()
	end, "trailGrid")

	FX.setters.trailSize = FX.stepper("st_trail_size", 50, 300, 25, Cfg.trailSize, function(v)
		return string.format("%d%%", v)
	end, 192, function(v)
		Cfg.trailSize = v
		FX.trailApplyAll()
		scheduleSave()
	end)

	FX.noteLabel("trail_hint", 193, 40)

	createSectionLabel({ key = "sec_impact" }, 200)

	FX.setters.shake = FX.stepper("st_shake", 0, 300, 25, Cfg.shake, function(v)
		return string.format("%d%%", v)
	end, 201, function(v)
		Cfg.shake = v
		scheduleSave()
	end)

	FX.setters.slowmo = FX.stepper("st_slow", 0, 3, 1, Cfg.slowmo, function(v)
		return FX.nameOf(FX.SLOW_NAMES[v] or FX.SLOW_NAMES[0])
	end, 202, function(v)
		Cfg.slowmo = v
		scheduleSave()
	end)

	FX.noteLabel("impact_hint", 203, 80)
end

do
	createSectionLabel({ key = "sec_cinema" }, 220)

	FX.toggle("cinema", "tg_cinema", 221)

	createSectionLabel({ key = "sec_cine_style" }, 222)

	FX.grid(223, FX.CINELIST, function()
		return Cfg.cineStyle
	end, function(id)
		Cfg.cineStyle = id
		FX.togglers.cineGrid()
		scheduleSave()
	end, "cineGrid")

	FX.toggle("cineBars", "tg_cinebars", 224)

	FX.setters.cineShake = FX.stepper("st_cine_shake", 0, 200, 25, Cfg.cineShake, function(v)
		return string.format("%d%%", v)
	end, 225, function(v)
		Cfg.cineShake = v
		scheduleSave()
	end)

	FX.setters.cineDist = FX.stepper("st_cine_dist", 50, 200, 10, Cfg.cineDist, function(v)
		return string.format("%d%%", v)
	end, 226, function(v)
		Cfg.cineDist = v
		scheduleSave()
	end)

	FX.noteLabel("cine_hint", 227, 80)

	FX.togglers.visualWords2 = function()
		FX.setters.slowmo(Cfg.slowmo, true)
		FX.setters.swarmFx(Cfg.swarmFx, true)
	end
end

do
	local hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(1, 0, 0, 72)
	hintLabel.BackgroundTransparency = 1
	FX.tr(hintLabel, "hint")
	hintLabel.TextColor3 = THEME.Muted
	hintLabel.TextSize = 10
	hintLabel.Font = Enum.Font.GothamMedium
	hintLabel.TextWrapped = true
	hintLabel.TextYAlignment = Enum.TextYAlignment.Top
	hintLabel.LayoutOrder = 99
	hintLabel.Parent = body
end

createSectionLabel({ key = "sec_swarm" }, 22)

SW.addButton = createButton(FX.L("btn_swarm_add"), body)
SW.addButton.LayoutOrder = 23

SW.clearButton = createButton({ key = "btn_swarm_clear" }, body)
SW.clearButton.LayoutOrder = 24

do
	local function swarmStep(key, label, min, max, step, order, fmt)
		FX.setters[key] = FX.stepper(label, min, max, step, Cfg[key], fmt, order, function(v)
			Cfg[key] = v
			scheduleSave()

			if SW.refresh then
				SW.refresh()
			end
		end)
	end

	do
		local maxSetters = {}

		local function onMax(v)
			Cfg.swarmMax = v
			scheduleSave()

			for _, st in ipairs(maxSetters) do
				st(v, true)
			end

			if SW.refresh then
				SW.refresh()
			end
		end

		for _, order in ipairs({ 25, 85 }) do
			table.insert(maxSetters, FX.stepper("st_swarm_max", 1, 8, 1, Cfg.swarmMax, function(v)
				return string.format("%d", v)
			end, order, onMax))
		end

		FX.setters.swarmMax = function(v)
			for _, st in ipairs(maxSetters) do
				st(v, true)
			end
		end
	end

	swarmStep("swarmScatter", "st_swarm_scatter", 1, 6, 0.5, 26, function(v)
		return string.format("%.1f s", v)
	end)

	swarmStep("swarmSpeed", "st_swarm_speed", 100, 800, 50, 27, function(v)
		return string.format("%d", v)
	end)

	swarmStep("swarmHeight", "st_swarm_height", 5, 30, 1, 28, function(v)
		return string.format("%d st", v)
	end)

	swarmStep("swarmRadius", "st_swarm_radius", 4, 30, 1, 29, function(v)
		return string.format("%d st", v)
	end)

	swarmStep("swarmOrbit", "st_swarm_orbit", 20, 240, 10, 30, function(v)
		return string.format("%d°/s", v)
	end)

	swarmStep("swarmSpread", "st_swarm_spread", 15, 100, 5, 31, function(v)
		return string.format("%d st", v)
	end)

	createSectionLabel({ key = "sec_orbit" }, 40)

	SW.addButton2 = createButton(FX.L("btn_swarm_add"), body)
	SW.addButton2.LayoutOrder = 41

	SW.clearButton2 = createButton({ key = "btn_swarm_clear" }, body)
	SW.clearButton2.LayoutOrder = 42

	SW.attackButton = createButton({ key = "btn_orbit_attack" }, body)
	SW.attackButton.LayoutOrder = 43

	createSectionLabel({ key = "sec_orbit_pick" }, 44)

	SW.refreshButton = createButton({ key = "btn_orbit_refresh" }, body)
	SW.refreshButton.Size = UDim2.new(1, 0, 0, 34)
	SW.refreshButton.TextSize = 12
	SW.refreshButton.LayoutOrder = 45

	SW.listFrame = Instance.new("Frame")
	SW.listFrame.Name = "TargetList"
	SW.listFrame.Size = UDim2.new(1, 0, 0, 0)
	SW.listFrame.AutomaticSize = Enum.AutomaticSize.Y
	SW.listFrame.BackgroundTransparency = 1
	SW.listFrame.LayoutOrder = 46
	SW.listFrame.Parent = body

	do
		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 6)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = SW.listFrame
	end

	local function tgtStep(key, label, min, max, step, order, fmt)
		FX.setters[key] = FX.stepper(label, min, max, step, Cfg[key], fmt, order, function(v)
			Cfg[key] = v
			scheduleSave()
		end)
	end

	tgtStep("tgtDist", "st_tgt_dist", 30, 60, 5, 47, function(v)
		return string.format("%d st", v)
	end)

	tgtStep("tgtOrbit", "st_tgt_orbit", 30, 240, 10, 48, function(v)
		return string.format("%d°/s", v)
	end)

	tgtStep("tgtDelay", "st_tgt_delay", 0, 6, 0.5, 49, function(v)
		return string.format("%.1f s", v)
	end)

	createSectionLabel({ key = "sec_tornado" }, 60)

	SW.addButton3 = createButton(FX.L("btn_swarm_add"), body)
	SW.addButton3.LayoutOrder = 61

	SW.clearButton3 = createButton({ key = "btn_swarm_clear" }, body)
	SW.clearButton3.LayoutOrder = 62

	SW.attackButton3 = createButton({ key = "btn_orbit_attack" }, body)
	SW.attackButton3.LayoutOrder = 63

	createSectionLabel({ key = "sec_orbit_pick" }, 64)

	SW.refreshButton3 = createButton({ key = "btn_orbit_refresh" }, body)
	SW.refreshButton3.Size = UDim2.new(1, 0, 0, 34)
	SW.refreshButton3.TextSize = 12
	SW.refreshButton3.LayoutOrder = 65

	SW.listFrame4 = Instance.new("Frame")
	SW.listFrame4.Name = "TornadoList"
	SW.listFrame4.Size = UDim2.new(1, 0, 0, 0)
	SW.listFrame4.AutomaticSize = Enum.AutomaticSize.Y
	SW.listFrame4.BackgroundTransparency = 1
	SW.listFrame4.LayoutOrder = 66
	SW.listFrame4.Parent = body

	do
		local listLayout4 = Instance.new("UIListLayout")
		listLayout4.Padding = UDim.new(0, 6)
		listLayout4.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout4.Parent = SW.listFrame4
	end

	tgtStep("tnRadius", "st_tn_radius", 20, 60, 5, 67, function(v)
		return string.format("%d st", v)
	end)

	tgtStep("tnHeight", "st_tn_height", 10, 50, 5, 68, function(v)
		return string.format("%d st", v)
	end)

	tgtStep("tnSpeed", "st_tn_speed", 60, 360, 20, 69, function(v)
		return string.format("%d°/s", v)
	end)

	tgtStep("tnDelay", "st_tn_delay", 0, 6, 0.5, 70, function(v)
		return string.format("%.1f s", v)
	end)

	tgtStep("tgtHeight", "st_swarm_height", 0, 40, 1, 50, function(v)
		return string.format("%d st", v)
	end)

	tgtStep("tnLift", "st_swarm_height", 0, 40, 1, 71, function(v)
		return string.format("%d st", v)
	end)

	createSectionLabel({ key = "sec_scatter" }, 80)

	SW.addButton4 = createButton(FX.L("btn_swarm_add"), body)
	SW.addButton4.LayoutOrder = 81

	SW.clearButton4 = createButton({ key = "btn_swarm_clear" }, body)
	SW.clearButton4.LayoutOrder = 82

	SW.launchButton4 = createButton({ key = "sw_launch" }, body)
	SW.launchButton4.LayoutOrder = 83

	tgtStep("scTime", "st_sc_time", 1, 6, 0.5, 84, function(v)
		return string.format("%.1f s", v)
	end)

	tgtStep("scDist", "st_sc_dist", 30, 150, 10, 86, function(v)
		return string.format("%d st", v)
	end)

	tgtStep("scSpin", "st_sc_spin", 90, 720, 30, 87, function(v)
		return string.format("%d°/s", v)
	end)

	tgtStep("scSpeed", "st_sc_speed", 100, 800, 50, 88, function(v)
		return string.format("%d", v)
	end)

	do
		local function sharedStep(key, label, min, max, step, orders, fmt)
			local setters = {}

			local function onChange(v)
				Cfg[key] = v
				scheduleSave()

				for _, st in ipairs(setters) do
					st(v, true)
				end
			end

			for _, order in ipairs(orders) do
				table.insert(setters, FX.stepper(label, min, max, step, Cfg[key], fmt, order, onChange))
			end

			FX.setters[key] = function(v)
				for _, st in ipairs(setters) do
					st(v, true)
				end
			end
		end

		sharedStep("nHeight", "st_n_height", 30, 250, 10, { 32, 52, 73, 90 }, function(v)
			return string.format("%d st", v)
		end)

		sharedStep("nGap", "st_n_gap", 0.5, 5, 0.5, { 33, 53, 74, 91 }, function(v)
			return string.format("%.1f s", v)
		end)
	end

	for _, order in ipairs({ 34, 54, 75, 92 }) do
		FX.toggle("cinema", "tg_cinema", order)
	end

	FX.setters.spinPower = function() end
end

function FX.rootOf(plr)
	local model = plr.Character

	return model and (
		model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Torso")
		or model:FindFirstChild("UpperTorso")
		or model:FindFirstChild("Head")
	) or nil
end

function SW.selectedPlayer()
	if SW.lockOn and SW.lockRoot and SW.lockRoot.Parent then
		return Players:GetPlayerFromCharacter(SW.lockRoot.Parent)
	end

	return nil
end

function SW.paintList()
	local sel = SW.selectedPlayer()

	for btn, plr in pairs(SW.listBtns) do
		if btn.Parent then
			if plr == sel then
				applyButtonStyle(btn, THEME.ErrorBase, THEME.Danger, 0.15)
			else
				applyButtonStyle(btn, THEME.Panel, THEME.Cyan, 0.75)
			end
		end
	end
end

function SW.buildList()
	for btn in pairs(SW.listBtns) do
		buttonStyles[btn] = nil
	end

	table.clear(SW.listBtns)

	local frames = { SW.listFrame, SW.listFrame4 }

	for _, frame in ipairs(frames) do
		for _, c in ipairs(frame:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
	end

	local players = {}

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and FX.allowed(plr) then
			local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")

			if hum and hum.Health > 0 and FX.rootOf(plr) then
				table.insert(players, plr)
			end
		end
	end

	for _, frame in ipairs(frames) do
		for n, plr in ipairs(players) do
			local b = createButton(plr.DisplayName .. "  (@" .. plr.Name .. ")", frame)

			b.Size = UDim2.new(1, 0, 0, 34)
			b.TextSize = 12
			b.TextTruncate = Enum.TextTruncate.AtEnd
			b.LayoutOrder = n

			SW.listBtns[b] = plr

			b.Activated:Connect(function()
				if SW.pickPlayer then
					SW.pickPlayer(plr)
				end
			end)
		end

		if #players == 0 then
			local l = Instance.new("TextLabel")
			l.Size = UDim2.new(1, 0, 0, 24)
			l.BackgroundTransparency = 1
			l.Text = FX.L("or_none")
			l.TextColor3 = THEME.Muted
			l.TextSize = 11
			l.Font = Enum.Font.GothamBold
			l.LayoutOrder = 1
			l.Parent = frame
		end
	end

	SW.paintList()
end

FX.conn(Players.PlayerAdded, function()
	task.delay(1, function()
		if FX.tab >= 3 then
			SW.buildList()
		end
	end)
end)

FX.conn(Players.PlayerRemoving, function()
	task.delay(0.2, function()
		if FX.tab >= 3 then
			SW.buildList()
		end
	end)
end)

FX.applyTab()

local menuVisible = true
local menuToken = 0

local menuAnim = Instance.new("NumberValue")
menuAnim.Name = "MenuAnim"
menuAnim.Value = 0
menuAnim.Parent = gui

local function applyMenuAnim()
	local a = menuAnim.Value
	menuScale.Scale = baseScale * scaleOf("menu") * (FX.pvFit or 1) * (0.8 + 0.2 * a)
	menu.GroupTransparency = math.clamp(1 - a, 0, 1)
end

menuAnim.Changed:Connect(applyMenuAnim)

function setMenuOpen(open, silent)
	-- FIX5: the menu stays closed until the daily verification is passed
	if open and FX.gateActive then
		return
	end

	menuVisible = open
	menuToken += 1

	local token = menuToken

	if not silent then
		playUI(open and "Open" or "Close")
	end

	tween(toggleIcon, 0.25, {
		ImageColor3 = open and Color3.new(1, 1, 1) or Color3.fromRGB(200, 205, 220),
	})

	if open then
		menu.Visible = true
		tween(menuAnim, 0.4, { Value = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	else
		local t = tween(menuAnim, 0.22, { Value = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		t.Completed:Connect(function()
			if token == menuToken and not menuVisible then
				menu.Visible = false
			end
		end)
	end
end

local function updateLayoutForViewport()
	local vp = getViewport()

	baseScale = math.clamp((vp.Y - 90) / K.MENU_H, 0.5, K.MAX_MENU_BASE_SCALE)
	applyMenuAnim()
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayoutForViewport)

register("menu", "MENU", menu, function()
	applyMenuAnim()
end)

toggle.InputBegan:Connect(function(input)
	if isPress(input) then
		beginDrag("toggle", input)
	end
end)

toggle.MouseEnter:Connect(function()
	playUI("Hover")
	tween(toggleScale, 0.15, { Scale = 1.1 })
end)

toggle.MouseLeave:Connect(function()
	tween(toggleScale, 0.2, { Scale = 1 })
end)

toggle.MouseButton1Down:Connect(function()
	tween(toggleScale, 0.08, { Scale = 0.9 })
end)

toggle.MouseButton1Up:Connect(function()
	tween(toggleScale, 0.25, { Scale = UIS.MouseEnabled and 1.1 or 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end)

toggle.Activated:Connect(function()
	if dragMoved.toggle or editMode then
		return
	end

	setMenuOpen(not menuVisible)
end)

FX.conn(RunService.Heartbeat, function()
	local r = (os.clock() * 40) % 360

	menuGradient.Rotation = r
	toggleGradient.Rotation = r
end)

-- ============================================================
-- XEVRION HUB  |  3D VISUAL PREVIEW + SAFE ZONE  (added in v36)
-- Opens next to the menu while the VISUAL tab is open:
--   * 3D copy of the map bomb you selected, with the texture pack (drag to rotate)
--   * 3D explosion preview of the selected effect (parts based)
--   * your character is moved to the safe place while you review
--     and is sent back to where you opened VISUAL when you leave
-- ============================================================
do
	local PV = {}

	FX.PV = PV

	local SAFE_POS = Vector3.new(-399.288, -7.350, 404.507)
	local PW, PH = 250, K.MENU_H
	local rng = FX.rng
	local Debris = FX.Debris
	local DARK = Color3.fromRGB(18, 18, 24)
	local WHITE = Color3.new(1, 1, 1)
	local CYAN = Color3.fromRGB(0, 210, 255)

	local S_EN = {
		pv_title = "3D PREVIEW",
		pv_safe = "SAFE ZONE",
		pv_spin = "SPIN",
		pv_test = "TEST",
		pv_boom = "BOOM",
		pv_world = "WORLD",
		pv_hint = "Drag to rotate  •  Scroll to zoom",
		pv_bomb = "BOMB",
		pv_fx = "EFFECT",
	}

	local S_ID = {
		pv_title = "PRATINJAU 3D",
		pv_safe = "ZONA AMAN",
		pv_spin = "PUTAR",
		pv_test = "UJI",
		pv_boom = "LEDAK",
		pv_world = "DUNIA",
		pv_hint = "Geser untuk memutar  •  Scroll untuk zoom",
		pv_bomb = "BOM",
		pv_fx = "EFEK",
	}

	for k, v in pairs(S_EN) do
		FX.STR.EN[k] = v
	end

	for k, v in pairs(S_ID) do
		FX.STR.ID[k] = v
	end

	-- --------------------------------------------------------
	-- state
	-- --------------------------------------------------------
	local st = {
		mode = "idle", -- idle | fly | boom | respawn
		t = 0,
		tok = 0,
		spin = true,
		spinA = 0,
		bobT = 0,
		yaw = 0.7,
		pitch = 0.2,
		dist = 9.5,
		distNow = 9.5,
		camT = Vector3.new(0, 2.1, 0),
		shake = 0,
		ext = 0,
		boomDur = 2,
		hue = 0,
		emitAcc = 0,
		hintGone = false,
		last = {},
		pendingBoom = nil,
		flyFrom = Vector3.new(0, 2.6, 0),
	}

	PV.st = st
	PV.active = false
	PV.lingerUntil = 0
	PV.hover = false

	-- --------------------------------------------------------
	-- panel (sits on the side of the menu)
	-- --------------------------------------------------------
	local panel = Instance.new("Frame")

	panel.Name = "XEV_Preview"
	panel.Size = UDim2.fromOffset(PW, PH)
	panel.BackgroundColor3 = Color3.fromRGB(60, 62, 72)
	panel.BorderSizePixel = 0
	panel.Active = true
	panel.Visible = false
	panel.ZIndex = 200
	panel.Parent = gui

	addCorner(panel, 18)

	local panelStroke = addStroke(panel, WHITE, 4, 0)
	local panelStrokeGrad = Instance.new("UIGradient")

	panelStrokeGrad.Color = ColorSequence.new(Color3.fromRGB(16, 16, 22))
	panelStrokeGrad.Parent = panelStroke

	local panelScale = Instance.new("UIScale")

	panelScale.Parent = panel

	local header = Instance.new("Frame")

	header.Size = UDim2.new(1, -12, 0, 30)
	header.Position = UDim2.fromOffset(6, 6)
	header.BackgroundColor3 = WHITE
	header.BorderSizePixel = 0
	header.Parent = panel

	addCorner(header, 10)
	addStroke(header, DARK, 2, 0)

	local headerGrad = Instance.new("UIGradient")

	headerGrad.Color = ColorSequence.new(Color3.fromRGB(255, 228, 118), Color3.fromRGB(245, 178, 46))
	headerGrad.Rotation = 90
	headerGrad.Parent = header

	local title = Instance.new("TextLabel")

	title.Size = UDim2.new(0.55, 0, 1, 0)
	title.Position = UDim2.fromOffset(10, 0)
	title.BackgroundTransparency = 1
	FX.tr(title, "pv_title")
	title.TextColor3 = WHITE
	title.TextSize = 15
	title.Font = Enum.Font.FredokaOne
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	do
		local s = addStroke(title, DARK, 2, 0)

		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	end

	local badge = Instance.new("Frame")

	badge.Size = UDim2.fromOffset(86, 18)
	badge.AnchorPoint = Vector2.new(1, 0.5)
	badge.Position = UDim2.new(1, -6, 0.5, 0)
	badge.BackgroundColor3 = Color3.fromRGB(84, 206, 62)
	badge.BorderSizePixel = 0
	badge.Parent = header

	addCorner(badge, 6)
	addStroke(badge, Color3.fromRGB(34, 98, 30), 2, 0)

	local badgeGrad = Instance.new("UIGradient")

	badgeGrad.Color = ColorSequence.new(WHITE, Color3.fromRGB(200, 224, 196))
	badgeGrad.Rotation = 90
	badgeGrad.Parent = badge

	local badgeText = Instance.new("TextLabel")

	badgeText.Size = UDim2.fromScale(1, 1)
	badgeText.BackgroundTransparency = 1
	FX.tr(badgeText, "pv_safe")
	badgeText.TextColor3 = WHITE
	badgeText.TextSize = 10
	badgeText.Font = Enum.Font.FredokaOne
	badgeText.Parent = badge

	do
		local s = addStroke(badgeText, Color3.fromRGB(34, 98, 30), 1.5, 0)

		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	end

	-- viewport box
	local stageBox = Instance.new("Frame")

	stageBox.Position = UDim2.fromOffset(6, 42)
	stageBox.Size = UDim2.new(1, -12, 0, 184)
	stageBox.BackgroundColor3 = WHITE
	stageBox.BorderSizePixel = 0
	stageBox.ClipsDescendants = true
	stageBox.Parent = panel

	addCorner(stageBox, 12)
	addStroke(stageBox, DARK, 2, 0)

	local stageBg = Instance.new("UIGradient")

	stageBg.Color = ColorSequence.new(Color3.fromRGB(38, 44, 84), Color3.fromRGB(8, 9, 16))
	stageBg.Rotation = 90
	stageBg.Parent = stageBox

	local AMBIENT = Color3.fromRGB(105, 110, 138)

	local vp = Instance.new("ViewportFrame")

	vp.Name = "Stage"
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundTransparency = 1
	vp.BorderSizePixel = 0
	vp.Ambient = AMBIENT
	vp.LightColor = Color3.fromRGB(255, 244, 228)
	vp.LightDirection = Vector3.new(-0.6, -1, -0.45)
	vp.Parent = stageBox

	local cam = Instance.new("Camera")

	cam.FieldOfView = 40
	cam.Parent = vp
	vp.CurrentCamera = cam

	addCorner(vp, 12)

	local flashFrame = Instance.new("Frame")

	flashFrame.Size = UDim2.fromScale(1, 1)
	flashFrame.BackgroundColor3 = WHITE
	flashFrame.BackgroundTransparency = 1
	flashFrame.BorderSizePixel = 0
	flashFrame.ZIndex = 3
	flashFrame.Parent = stageBox

	addCorner(flashFrame, 12)

	local hint = Instance.new("TextLabel")

	hint.Size = UDim2.new(1, -8, 0, 14)
	hint.Position = UDim2.new(0, 4, 1, -17)
	hint.BackgroundTransparency = 1
	FX.tr(hint, "pv_hint")
	hint.TextColor3 = Color3.fromRGB(190, 198, 222)
	hint.TextTransparency = 0.25
	hint.TextSize = 9
	hint.Font = Enum.Font.GothamMedium
	hint.ZIndex = 4
	hint.Parent = stageBox

	local cap = Instance.new("TextButton")

	cap.Size = UDim2.fromScale(1, 1)
	cap.BackgroundTransparency = 1
	cap.Text = ""
	cap.AutoButtonColor = false
	cap.ZIndex = 5
	cap.Parent = stageBox

	cap.MouseEnter:Connect(function()
		PV.hover = true
	end)

	cap.MouseLeave:Connect(function()
		PV.hover = false
	end)

	-- info label
	local info = Instance.new("TextLabel")

	info.Size = UDim2.new(1, -12, 0, 32)
	info.Position = UDim2.fromOffset(6, 229)
	info.BackgroundTransparency = 1
	info.RichText = true
	info.TextColor3 = WHITE
	info.TextSize = 11
	info.Font = Enum.Font.GothamBold
	info.Parent = panel

	local function infoText()
		local skin = FX.skinById[Cfg.skinId or "original"]
		local fx = FX.fxById[Cfg.fxId or "classic"]

		return string.format(
			'<font color="rgb(140,149,172)">%s</font>  <font color="rgb(255,214,90)">%s</font>\n<font color="rgb(140,149,172)">%s</font>  <font color="rgb(90,225,255)">%s</font>',
			FX.L("pv_bomb"),
			skin and FX.nameOf(skin) or "?",
			FX.L("pv_fx"),
			fx and FX.nameOf(fx) or "?"
		)
	end

	FX.tr(info, "pv_bomb", infoText)

	function PV.refreshInfo()
		info.Text = infoText()
	end

	-- buttons
	local btnSpin = createButton({ key = "pv_spin" }, panel)
	local btnTest = createButton({ key = "pv_test" }, panel)
	local btnBoom = createButton({ key = "pv_boom" }, panel)
	local btnWorld = createButton({ key = "pv_world" }, panel)

	for i, b in ipairs({ btnSpin, btnTest, btnBoom, btnWorld }) do
		b.Size = UDim2.fromOffset(54, 38)
		b.Position = UDim2.fromOffset(6 + (i - 1) * 61.33, 266)
		b.TextSize = 12
	end

	local function paintSpin()
		if st.spin then
			applyButtonStyle(btnSpin, THEME.OnBase, THEME.Accent, 0.3)
		else
			applyButtonStyle(btnSpin, THEME.Panel, THEME.Cyan, 0.75)
		end
	end

	paintSpin()

	-- fade overlay used when teleporting
	local fadeFrame = Instance.new("Frame")

	fadeFrame.Name = "XEV_PreviewFade"
	fadeFrame.Size = UDim2.fromScale(1, 1)
	fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	fadeFrame.BackgroundTransparency = 1
	fadeFrame.BorderSizePixel = 0
	fadeFrame.ZIndex = 300
	fadeFrame.Parent = gui

	local function fade()
		fadeFrame.BackgroundTransparency = 0.15
		tween(fadeFrame, 0.6, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end

	-- --------------------------------------------------------
	-- 3D world
	-- --------------------------------------------------------
	local world = Instance.new("Model")

	world.Name = "World"
	world.Parent = vp

	local fxModel = Instance.new("Model")

	fxModel.Name = "Fx"
	fxModel.Parent = vp

	local function newPart(shape, color, size, cf, transp, mat, parent)
		local p = Instance.new("Part")

		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Shape = shape or Enum.PartType.Block
		p.Material = mat or Enum.Material.Neon
		p.Color = color
		p.Transparency = transp or 0
		p.Size = size
		p.CFrame = cf or CFrame.new()
		p.Parent = parent or fxModel

		return p
	end

	local CYL = Enum.PartType.Cylinder
	local BALL = Enum.PartType.Ball
	local BLOCK = Enum.PartType.Block
	local FLAT = CFrame.Angles(0, 0, math.pi / 2)

	local accentParts = {}
	local twinkle = {}
	local floorRings = {}

	-- floor + pedestal
	do
		newPart(CYL, Color3.fromRGB(14, 16, 26), Vector3.new(0.4, 18, 18), CFrame.new(0, -0.2, 0) * FLAT, 0, Enum.Material.SmoothPlastic, world).Reflectance = 0.12

		for i, d in ipairs({ 4.6, 7.4, 10.6, 14.2 }) do
			local r = newPart(CYL, CYAN, Vector3.new(0.04, d, d), CFrame.new(0, 0.03, 0) * FLAT, 0.55, Enum.Material.Neon, world)

			table.insert(accentParts, r)
			table.insert(floorRings, r)
		end

		local edge = newPart(CYL, CYAN, Vector3.new(0.1, 17.8, 17.8), CFrame.new(0, 0.04, 0) * FLAT, 0.35, Enum.Material.Neon, world)

		table.insert(accentParts, edge)

		newPart(CYL, Color3.fromRGB(36, 40, 54), Vector3.new(0.5, 3.4, 3.4), CFrame.new(0, 0.25, 0) * FLAT, 0, Enum.Material.Metal, world).Reflectance = 0.2

		local pedRing = newPart(CYL, CYAN, Vector3.new(0.1, 3.5, 3.5), CFrame.new(0, 0.5, 0) * FLAT, 0.1, Enum.Material.Neon, world)

		table.insert(accentParts, pedRing)

		local pedTop = newPart(CYL, Color3.fromRGB(20, 22, 32), Vector3.new(0.06, 2.9, 2.9), CFrame.new(0, 0.52, 0) * FLAT, 0, Enum.Material.SmoothPlastic, world)

		pedTop.Reflectance = 0.1

		-- stars
		for i = 1, 30 do
			local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.2, 1), rng:NextNumber(-1, 1))

			if dir.Magnitude < 0.1 then
				dir = Vector3.new(0, 1, 0)
			end

			local s = rng:NextNumber(0.06, 0.16)
			local star = newPart(BALL, Color3.fromRGB(200, 220, 255), Vector3.new(s, s, s), CFrame.new(dir.Unit * rng:NextNumber(12, 22) + Vector3.new(0, 4, 0)), 0.2, Enum.Material.Neon, world)

			table.insert(twinkle, { p = star, ph = rng:NextNumber(0, 6.28), sp = rng:NextNumber(1, 3) })
		end
	end

	-- bomb model (axis along Z, nose points to -Z)
	local bomb = {
		model = Instance.new("Model"),
		hull = {},
		bands = {},
		plates = {},
		decals = {},
		def = nil,
	}

	do
		local m = bomb.model

		m.Name = "Bomb"

		local pivot = newPart(BLOCK, WHITE, Vector3.new(0.1, 0.1, 0.1), CFrame.new(), 1, Enum.Material.SmoothPlastic, m)

		m.PrimaryPart = pivot

		local function hull(role, shape, size, cf, mesh)
			local p = newPart(shape, WHITE, size, cf, 0, Enum.Material.Metal, m)

			if mesh then
				local sm = Instance.new("SpecialMesh")

				sm.MeshType = Enum.MeshType.Sphere
				sm.Parent = p
			end

			table.insert(bomb.hull, { part = p, role = role })

			return p
		end

		local ALONG = CFrame.Angles(0, math.pi / 2, 0)

		hull("body", CYL, Vector3.new(2.0, 1.0, 1.0), ALONG)
		hull("nose", BLOCK, Vector3.new(1.0, 1.0, 1.15), CFrame.new(0, 0, -1.0), true)
		hull("tail", BLOCK, Vector3.new(0.82, 0.82, 1.3), CFrame.new(0, 0, 1.12), true)

		for k = 0, 3 do
			local fin = Instance.new("WedgePart")

			fin.Anchored = true
			fin.CanCollide = false
			fin.CanQuery = false
			fin.CanTouch = false
			fin.CastShadow = false
			fin.Size = Vector3.new(0.08, 0.7, 0.85)
			fin.Material = Enum.Material.Metal
			fin.CFrame = CFrame.Angles(0, 0, k * math.pi / 2) * CFrame.new(0, 0.74, 1.2)
			fin.Parent = m

			table.insert(bomb.hull, { part = fin, role = "fin" })
		end

		for _, z in ipairs({ -0.5, 0.45 }) do
			local band = newPart(CYL, WHITE, Vector3.new(0.16, 1.06, 1.06), CFrame.new(0, 0, z) * ALONG, 0, Enum.Material.Neon, m)

			table.insert(bomb.bands, band)
		end

		-- custom id plates (only visible with a custom texture id)
		for _, sx in ipairs({ 1, -1 }) do
			local plate = newPart(BLOCK, Color3.fromRGB(40, 42, 50), Vector3.new(0.05, 0.85, 1.0), CFrame.new(sx * 0.51, 0, -0.1), 0, Enum.Material.SmoothPlastic, m)

			plate.Transparency = 1

			table.insert(bomb.plates, { part = plate, face = sx == 1 and Enum.NormalId.Right or Enum.NormalId.Left })
		end

		bomb.aura = newPart(BALL, WHITE, Vector3.new(3.1, 3.1, 3.1), CFrame.new(), 1, Enum.Material.Neon, m)

		m.Parent = vp
	end

	bomb.b = {
		model = bomb.model,
		hull = bomb.hull,
		bands = bomb.bands,
		plates = bomb.plates,
		aura = bomb.aura,
	}

	local ORIG = {
		body = Color3.fromRGB(64, 68, 80),
		nose = Color3.fromRGB(206, 58, 52),
		tail = Color3.fromRGB(64, 68, 80),
		fin = Color3.fromRGB(206, 58, 52),
	}

	local function bombPose(cf)
		bomb.model:PivotTo(cf)
	end

	-- --------------------------------------------------------
	-- real map bomb: the bomb you selected (or the nearest bomb of the map)
	-- is cloned into the preview. The built model is only a fallback.
	-- --------------------------------------------------------
	PV.BOM_PAT = { "[Bb][Oo][Mm]", "[Mm]issile", "[Rr]udal", "[Rr]ocket" }

	function PV.bomName(n)
		for _, p in ipairs(PV.BOM_PAT) do
			if string.find(n, p) then
				return true
			end
		end

		return false
	end

	function PV.scanBombs()
		local ch = LP.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local from = hrp and hrp.Position or Camera.CFrame.Position
		local best, bestD

		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 0.95 then
				local par = d.Parent
				local hit = PV.bomName(d.Name) or (par and par ~= workspace and PV.bomName(par.Name))

				if hit then
					local sz = d.Size
					local mx = math.max(sz.X, sz.Y, sz.Z)

					if mx <= 40 then
						local m = d:FindFirstAncestorOfClass("Model")
						local isChar = m and (Players:GetPlayerFromCharacter(m) ~= nil or m:FindFirstChildOfClass("Humanoid") ~= nil)

						if not isChar then
							local dist = (d.Position - from).Magnitude

							if not bestD or dist < bestD then
								best, bestD = d, dist
							end
						end
					end
				end
			end
		end

		return best
	end

	function PV.findSource(force)
		local cand = selectedBomb

		if not (cand and cand.Parent and cand:IsA("BasePart")) then
			local V2 = FX.V2

			cand = V2 and V2.center
		end

		if not (cand and typeof(cand) == "Instance" and cand.Parent and cand:IsA("BasePart")) then
			local first = SW.bombs[1]

			cand = first and first.part
		end

		if cand and typeof(cand) == "Instance" and cand.Parent and cand:IsA("BasePart") then
			return cand
		end

		local now = os.clock()

		if force or (not (PV.scanned and PV.scanned.Parent) and now - (PV.scanAt or 0) > 8) then
			PV.scanAt = now
			PV.scanned = PV.scanBombs()
		end

		if PV.scanned and PV.scanned.Parent then
			return PV.scanned
		end

		return nil
	end

	function PV.setModelSet(set, isReal)
		local old = bomb.model
		local shown = old and old.Parent ~= nil

		if old and old ~= set.model then
			old.Parent = nil
		end

		bomb.model = set.model
		bomb.hull = set.hull
		bomb.bands = set.bands
		bomb.plates = set.plates
		bomb.aura = set.aura
		bomb.isReal = isReal
		bomb.model.Parent = shown and vp or nil
	end

	function PV.useBuilt()
		PV.setModelSet(bomb.b, false)

		if bomb.real then
			pcall(function()
				bomb.real:Destroy()
			end)

			bomb.real = nil
		end
	end

	function PV.buildReal(part)
		-- take the whole bomb model when the part sits inside a small "bomb" model
		local root = part
		local par = part.Parent

		if par and par ~= workspace and par:IsA("Model") and not par:FindFirstChildOfClass("Humanoid") and PV.bomName(par.Name) then
			local n = 0

			for _, d in ipairs(par:GetDescendants()) do
				if d:IsA("BasePart") then
					n = n + 1
				end
			end

			if n >= 1 and n <= 60 then
				root = par
			end
		end

		local ok, clone = pcall(function()
			return root:Clone()
		end)

		if not ok or not clone then
			return nil
		end

		local function list(r)
			local t = { r }

			for _, d in ipairs(r:GetDescendants()) do
				t[#t + 1] = d
			end

			return t
		end

		local sl, cl = list(root), list(clone)
		local aligned = #sl == #cl
		local hull = {}
		local visible = false

		for i, c in ipairs(cl) do
			local s = aligned and sl[i] or nil

			if c:IsA("BasePart") then
				local o = s and FX.skinOrig[s] or nil

				local rec = {
					Color = o and o.Color or c.Color,
					Material = o and o.Material or c.Material,
					Reflectance = o and o.Reflectance or c.Reflectance,
					Transparency = o and o.Transparency or c.Transparency,
				}

				if c:IsA("MeshPart") then
					rec.TextureID = o and o.TextureID or c.TextureID
				end

				if rec.Transparency < 0.95 then
					visible = true
				end

				hull[#hull + 1] = { part = c, role = "real", orig = rec }
			end
		end

		if #hull == 0 then
			pcall(function()
				clone:Destroy()
			end)

			return nil
		end

		if not visible then
			for _, h in ipairs(hull) do
				h.orig.Transparency = 0
			end
		end

		-- clean the copy: no scripts, sounds, physics, or leftovers of the hub skin
		for _, c in ipairs(cl) do
			if c.Parent then
				if c.Name == FX.skinMark or c:IsA("BaseScript") or c:IsA("Sound") or c:IsA("Constraint") or c:IsA("BodyMover") or c:IsA("Humanoid") or c:IsA("Trail") or c:IsA("Beam") then
					pcall(function()
						c:Destroy()
					end)
				end
			end
		end

		for _, h in ipairs(hull) do
			local p = h.part

			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Transparency = h.orig.Transparency
		end

		local wrap = clone

		if clone:IsA("BasePart") then
			wrap = Instance.new("Model")
			clone.Parent = wrap
			wrap.PrimaryPart = clone
		elseif not wrap.PrimaryPart then
			local big, bigV = nil, -1

			for _, h in ipairs(hull) do
				local sz = h.part.Size
				local v = sz.X * sz.Y * sz.Z

				if v > bigV then
					big, bigV = h.part, v
				end
			end

			wrap.PrimaryPart = big
		end

		wrap.Name = "MapBomb"

		local holder = Instance.new("Model")

		holder.Name = "Bomb"

		local pivot = newPart(BLOCK, WHITE, Vector3.new(0.1, 0.1, 0.1), CFrame.new(), 1, Enum.Material.SmoothPlastic, holder)

		holder.PrimaryPart = pivot
		wrap.Parent = holder

		-- size it to the stage, put the box centre on the pivot and the long side along Z
		local _, size0 = wrap:GetBoundingBox()
		local k = 3.6 / math.max(size0.X, size0.Y, size0.Z, 0.05)

		pcall(function()
			wrap:ScaleTo(wrap:GetScale() * k)
		end)

		local box, size1 = wrap:GetBoundingBox()
		local rel = box:ToObjectSpace(wrap:GetPivot())
		local rot = CFrame.new()

		if size1.X >= size1.Y and size1.X >= size1.Z then
			rot = CFrame.Angles(0, math.pi / 2, 0)
		elseif size1.Y >= size1.X and size1.Y >= size1.Z then
			rot = CFrame.Angles(math.pi / 2, 0, 0)
		end

		wrap:PivotTo(rot * rel)

		local aura = newPart(BALL, WHITE, Vector3.new(4.4, 4.4, 4.4), CFrame.new(), 1, Enum.Material.Neon, holder)

		return { model = holder, hull = hull, bands = {}, plates = {}, aura = aura }
	end

	function PV.setSource(part)
		local set

		if part and part.Parent then
			local ok, res = pcall(PV.buildReal, part)

			if ok then
				set = res
			else
				warn("[XEVRION HUB] preview bomb error: " .. tostring(res))
			end
		end

		if set then
			local oldReal = bomb.real

			PV.setModelSet(set, true)
			bomb.real = set.model

			if oldReal and oldReal ~= set.model then
				pcall(function()
					oldReal:Destroy()
				end)
			end
		else
			PV.useBuilt()
		end

		PV.applySkin()
	end

	function PV.refreshSource(force)
		local want = PV.findSource(force)

		if force or want ~= PV.srcPart then
			PV.srcPart = want
			PV.setSource(want)
		end
	end

	function PV.applySkin()
		local id = Cfg.skinId or "original"
		local def = FX.SKINS[id]

		for _, d in ipairs(bomb.decals) do
			pcall(function()
				d:Destroy()
			end)
		end

		bomb.decals = {}

		local useDef = (id ~= "original" and id ~= "custom") and def or nil

		bomb.def = useDef

		for _, h in ipairs(bomb.hull) do
			local p = h.part
			local o = h.orig

			if useDef then
				p.Color = useDef.color
				p.Material = useDef.mat
				p.Reflectance = useDef.refl or 0
				p.Transparency = o and math.max(o.Transparency, useDef.trans or 0) or (useDef.trans or 0)
			elseif o then
				p.Color = o.Color
				p.Material = o.Material
				p.Reflectance = o.Reflectance
				p.Transparency = o.Transparency
			else
				p.Color = ORIG[h.role]
				p.Material = Enum.Material.Metal
				p.Reflectance = 0.12
				p.Transparency = 0
			end

			if o and o.TextureID ~= nil then
				pcall(function()
					p.TextureID = o.TextureID
				end)
			end
		end

		for _, b in ipairs(bomb.bands) do
			if useDef then
				b.Color = useDef.glow or useDef.color:Lerp(WHITE, 0.4)
				b.Material = useDef.glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
			else
				b.Color = Color3.fromRGB(245, 205, 70)
				b.Material = Enum.Material.Neon
			end
		end

		local glow = useDef and useDef.glow

		bomb.aura.Color = glow or WHITE
		bomb.aura.Transparency = glow and 0.9 or 1

		local num = id == "custom" and string.match(tostring(Cfg.skinCustom or ""), "%d+")

		for _, pl in ipairs(bomb.plates) do
			if num then
				pl.part.Transparency = 0

				local d = Instance.new("Decal")

				d.Texture = "rbxassetid://" .. num
				d.Face = pl.face
				d.Parent = pl.part

				table.insert(bomb.decals, d)
			else
				pl.part.Transparency = 1
			end
		end

		if num then
			for _, h in ipairs(bomb.hull) do
				if h.role == "fin" then
					for _, face in ipairs({ Enum.NormalId.Right, Enum.NormalId.Left }) do
						local d = Instance.new("Decal")

						d.Texture = "rbxassetid://" .. num
						d.Face = face
						d.Parent = h.part

						table.insert(bomb.decals, d)
					end
				end
			end
		end

		if num and bomb.isReal then
			local url = "rbxassetid://" .. num

			for i, h in ipairs(bomb.hull) do
				if i > 40 then
					break
				end

				local p = h.part

				if p.Transparency < 0.95 then
					if p:IsA("MeshPart") then
						pcall(function()
							p.TextureID = url
						end)
					end

					for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
						local tx = Instance.new("Texture")

						tx.Texture = url
						tx.Face = face
						tx.StudsPerTileU = 2
						tx.StudsPerTileV = 2
						tx.Parent = p

						table.insert(bomb.decals, tx)
					end
				end
			end
		end

		-- stage accent follows the skin
		local accent = (useDef and (useDef.glow or useDef.trail or useDef.color)) or CYAN

		for _, a in ipairs(accentParts) do
			tween(a, 0.35, { Color = accent })
		end

		PV.refreshInfo()
	end

	-- --------------------------------------------------------
	-- particles (parts based, ParticleEmitters do not render in a ViewportFrame)
	-- --------------------------------------------------------
	local parts = {}
	local tickers = {}
	local MAXP = 170

	local function unitRand()
		local v = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))

		if v.Magnitude < 0.05 then
			return Vector3.new(0, 1, 0)
		end

		return v.Unit
	end

	local function rnd(r)
		return unitRand() * rng:NextNumber(0.2, 1) * r
	end

	local function cnt(n, minN)
		return math.max(minN or 2, math.floor(n * FX.lagK() + 0.5))
	end

	local function emit(at, vel, c0, c1, s0, s1, life, o)
		if #parts >= MAXP then
			return
		end

		o = o or {}

		local p = newPart(o.shape or BALL, c0, Vector3.new(s0, s0, s0), CFrame.new(at), o.t0 or 0, o.mat or Enum.Material.Neon, fxModel)

		parts[#parts + 1] = {
			p = p,
			pos = at,
			vel = vel,
			c0 = c0,
			c1 = c1 or c0,
			s0 = s0,
			s1 = s1,
			life = life,
			t = 0,
			t0 = o.t0 or 0,
			t1 = o.t1 or 1,
			grav = o.grav or 0,
			drag = o.drag or 0,
			swirl = o.swirl,
			flat = o.flat,
			tumble = o.tumble,
			rx = rng:NextNumber(0, 6.28),
			ry = rng:NextNumber(0, 6.28),
			sx = rng:NextNumber(-7, 7),
			sy = rng:NextNumber(-7, 7),
		}
	end

	-- burst: o.speed {min,max}, o.life {min,max}, o.c0/o.c1 or o.cols, o.s0/o.s1, o.grav, o.drag,
	-- o.up (bias), o.flatY (horizontal ring), o.inward (spawn radius, fly to centre), o.swirl, o.shape, o.mat
	local function burst(pos, n, o)
		n = cnt(n, 3)

		local sp = o.speed or { 2, 6 }
		local lf = o.life or { 0.6, 1.2 }

		for _ = 1, n do
			local dir = unitRand()

			if o.up then
				dir = (dir + Vector3.new(0, o.up, 0)).Unit
			end

			if o.flatY then
				dir = Vector3.new(dir.X, dir.Y * 0.12, dir.Z).Unit
			end

			local speed = rng:NextNumber(sp[1], sp[2])
			local at = pos
			local vel = dir * speed

			if o.inward then
				at = pos + dir * o.inward
				vel = -dir * speed
			end

			local c0 = o.c0 or WHITE

			if o.cols then
				c0 = o.cols[rng:NextInteger(1, #o.cols)]
			end

			emit(at, vel, c0, o.c1, o.s0 or 0.3, o.s1 or 0.05, rng:NextNumber(lf[1], lf[2]), o)
		end
	end

	local function stepParticles(dt)
		local i = 1

		while i <= #parts do
			local d = parts[i]
			local p = d.p

			d.t = d.t + dt

			if d.t >= d.life or not p.Parent then
				pcall(function()
					p:Destroy()
				end)

				parts[i] = parts[#parts]
				parts[#parts] = nil
			else
				local a = d.t / d.life

				if d.drag > 0 then
					d.vel = d.vel * math.max(0, 1 - d.drag * dt)
				end

				if d.swirl then
					d.vel = CFrame.Angles(0, d.swirl * dt, 0):VectorToWorldSpace(d.vel)
				end

				d.vel = Vector3.new(d.vel.X, d.vel.Y - d.grav * dt, d.vel.Z)
				d.pos = d.pos + d.vel * dt

				local s = math.max(d.s0 + (d.s1 - d.s0) * a, 0.02)

				if d.flat then
					p.Size = Vector3.new(s, s * 0.12, s * 0.7)
				else
					p.Size = Vector3.new(s, s, s)
				end

				if d.flat or d.tumble then
					d.rx = d.rx + d.sx * dt
					d.ry = d.ry + d.sy * dt
					p.CFrame = CFrame.new(d.pos) * CFrame.Angles(d.rx, d.ry, 0)
				else
					p.CFrame = CFrame.new(d.pos)
				end

				p.Transparency = d.t0 + (d.t1 - d.t0) * a

				if d.c1 ~= d.c0 then
					p.Color = d.c0:Lerp(d.c1, a)
				end

				i = i + 1
			end
		end
	end

	local function stepTickers(dt)
		local i = 1

		while i <= #tickers do
			local ok, done = pcall(tickers[i], dt)

			if not ok or done then
				tickers[i] = tickers[#tickers]
				tickers[#tickers] = nil
			else
				i = i + 1
			end
		end
	end

	-- --------------------------------------------------------
	-- effect helpers
	-- --------------------------------------------------------
	local function tw(obj, t, props, style, dir)
		local ok, res = pcall(function()
			local x = TweenService:Create(obj, TweenInfo.new(
				math.max(t, 0.03),
				style or Enum.EasingStyle.Quad,
				dir or Enum.EasingDirection.Out
			), props)

			x:Play()

			return x
		end)

		return ok and res or nil
	end

	local function life(inst, t)
		Debris:AddItem(inst, t)
	end

	local function later(t, fn)
		local tok = st.tok

		task.delay(t, function()
			if st.tok ~= tok then
				return
			end

			pcall(fn)
		end)
	end

	local function col(default)
		return FX.E.col(default)
	end

	local function sphere(pos, color, maxSize, t, startT, mat, endT)
		local p = newPart(BALL, color, Vector3.new(0.3, 0.3, 0.3), CFrame.new(pos), startT or 0.2, mat)

		tw(p, t, { Size = Vector3.new(maxSize, maxSize, maxSize), Transparency = endT or 1 })
		life(p, t + 0.2)

		return p
	end

	local function ring(pos, color, maxSize, t, thick, tilt)
		local cf = CFrame.new(pos) * (tilt or CFrame.new()) * FLAT
		local p = newPart(CYL, color, Vector3.new(thick or 0.2, 0.5, 0.5), cf, 0.15)

		tw(p, t, { Size = Vector3.new(thick or 0.2, maxSize, maxSize), Transparency = 1 })
		life(p, t + 0.2)

		return p
	end

	local function bolt(a, b, color, thick, t)
		local segs = 6
		local prev = a
		local dir = b - a

		for i = 1, segs do
			local nextP = a + dir * (i / segs)

			if i < segs then
				nextP = nextP + rnd(dir.Magnitude * 0.12)
			end

			local len = (nextP - prev).Magnitude

			if len > 0.04 then
				local p = newPart(BLOCK, color, Vector3.new(thick, thick, len), CFrame.lookAt(prev, nextP) * CFrame.new(0, 0, -len / 2), 0)

				tw(p, t, { Transparency = 1, Size = Vector3.new(thick * 0.2, thick * 0.2, len) })
				life(p, t + 0.2)
			end

			prev = nextP
		end
	end

	local function flashScreen(color, alpha, t)
		flashFrame.BackgroundColor3 = color
		flashFrame.BackgroundTransparency = alpha
		tw(flashFrame, t, { BackgroundTransparency = 1 })
	end

	local function lightPulse(color, t)
		vp.Ambient = color:Lerp(WHITE, 0.25)
		tw(vp, t, { Ambient = AMBIENT })
	end

	local function shake(a)
		st.shake = math.max(st.shake, a)
	end

	-- --------------------------------------------------------
	-- the 14 explosion effects (view versions, same colours / ideas as the game ones)
	-- --------------------------------------------------------
	local FXV = {}

	local function floorPt(c)
		return Vector3.new(c.X, 0.12, c.Z)
	end

	function FXV.classic(c, R, T)
		local orange = col(Color3.fromRGB(255, 150, 40))
		local yellow = Color3.fromRGB(255, 225, 110)

		flashScreen(Color3.fromRGB(255, 220, 160), 0.55, 0.35 * T)
		lightPulse(orange, 0.6 * T)
		shake(0.7)

		sphere(c, WHITE, R * 1.0, 0.22 * T, 0)
		sphere(c, yellow, R * 1.7, 0.45 * T, 0.05)
		sphere(c, orange, R * 2.3, 0.8 * T, 0.25)
		ring(floorPt(c), orange, R * 5.5, 0.7 * T, 0.12)

		burst(c, 30, { speed = { R * 2.5, R * 7 }, life = { 0.5, 1.1 }, c0 = yellow, c1 = orange, s0 = 0.32, s1 = 0.04, grav = 10, drag = 1 })
		burst(c, 14, { speed = { R * 1.5, R * 4.5 }, life = { 0.9, 1.5 }, c0 = Color3.fromRGB(70, 62, 56), s0 = 0.26, s1 = 0.1, grav = 22, shape = BLOCK, mat = Enum.Material.Concrete, tumble = true, t1 = 0.6 })
		burst(c + Vector3.new(0, 0.3, 0), 10, { speed = { 0.5, R * 1.1 }, life = { 1.1, 1.8 }, c0 = Color3.fromRGB(86, 80, 78), c1 = Color3.fromRGB(30, 30, 30), s0 = R * 0.45, s1 = R * 1.4, up = 1.2, t0 = 0.35, t1 = 1, mat = Enum.Material.SmoothPlastic })
	end

	function FXV.blackhole(c, R, T)
		local purple = col(Color3.fromRGB(150, 70, 255))
		local orange = col(Color3.fromRGB(255, 140, 40))
		local grow, hold, collapse = 0.7 * T, 1.9 * T, 0.5 * T
		local total = grow + hold + collapse

		lightPulse(purple, total)
		shake(0.25)

		local core = newPart(BALL, Color3.new(0, 0, 0), Vector3.new(0.3, 0.3, 0.3), CFrame.new(c), 0, Enum.Material.SmoothPlastic)

		tw(core, grow, { Size = Vector3.new(R * 0.9, R * 0.9, R * 0.9) }, Enum.EasingStyle.Back)
		life(core, total + 0.3)

		local halo = newPart(BALL, purple, Vector3.new(0.3, 0.3, 0.3), CFrame.new(c), 0.55)

		tw(halo, grow, { Size = Vector3.new(R * 1.25, R * 1.25, R * 1.25) })
		life(halo, total + 0.3)

		local discs = {}

		for i = 1, 2 do
			local d = newPart(CYL, i == 1 and orange or purple, Vector3.new(0.1, 0.5, 0.5), CFrame.new(c) * FLAT, i == 1 and 0.35 or 0.55)
			local dia = R * (2.3 - (i - 1) * 0.7)

			tw(d, grow, { Size = Vector3.new(0.1, dia, dia) })
			life(d, total + 0.3)

			table.insert(discs, { part = d, tilt = (i - 1) * 0.35, dir = i == 1 and 1 or -1 })
		end

		local t0 = os.clock()
		local acc = 0

		table.insert(tickers, function(dt)
			local t = os.clock() - t0

			if t > grow + hold then
				return true
			end

			for _, d in ipairs(discs) do
				if d.part.Parent then
					d.part.CFrame = CFrame.new(c) * CFrame.Angles(0, t * 5 * d.dir, 0) * CFrame.Angles(0.45 + d.tilt, 0, 0) * FLAT
				end
			end

			acc = acc + dt

			if acc > 0.035 then
				acc = 0

				burst(c, 2, { inward = R * 1.9, speed = { R * 2.4, R * 3.6 }, life = { 0.4, 0.6 }, c0 = orange, c1 = purple, s0 = 0.26, s1 = 0.03 })
			end

			return false
		end)

		later(grow + hold, function()
			tw(core, collapse, { Size = Vector3.new(0.3, 0.3, 0.3) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			tw(halo, collapse, { Size = Vector3.new(0.3, 0.3, 0.3), Transparency = 1 })

			for _, d in ipairs(discs) do
				tw(d.part, collapse, { Size = Vector3.new(0.1, 0.4, 0.4), Transparency = 1 })
			end
		end)

		later(total, function()
			flashScreen(WHITE, 0.4, 0.5 * T)
			shake(0.6)
			ring(floorPt(c), purple, R * 5, 0.8 * T, 0.2)
			sphere(c, WHITE, R * 2.4, 0.5 * T, 0.1)
			burst(c, 36, { speed = { R * 1.5, R * 4 }, life = { 0.7, 1.4 }, c0 = purple, c1 = orange, s0 = 0.4, s1 = 0.04, drag = 0.8 })
		end)
	end

	function FXV.nuke(c, R, T)
		local orange = col(Color3.fromRGB(255, 130, 30))
		local yellow = col(Color3.fromRGB(255, 220, 90))

		flashScreen(Color3.fromRGB(255, 240, 200), 0.3, 0.9 * T)
		lightPulse(yellow, 1.0 * T)
		shake(1)

		sphere(c, WHITE, R * 1.6, 0.35 * T, 0)
		sphere(c, orange, R * 2.2, 1.0 * T, 0.1)
		ring(floorPt(c), yellow, R * 6.5, 1.0 * T, 0.2)

		burst(c, 34, { speed = { R * 0.8, R * 3 }, life = { 0.8, 1.5 }, c0 = yellow, c1 = orange, s0 = R * 0.12, s1 = 0.04, grav = -2, drag = 0.6, up = 0.5 })

		local steps = 6

		for i = 1, steps do
			later((i - 1) * 0.12 * T, function()
				local size = R * (i == steps and 2.1 or 0.75)
				local p = newPart(BALL, i == steps and orange or yellow, Vector3.new(size * 0.4, size * 0.4, size * 0.4), CFrame.new(c + Vector3.new(0, i * R * 0.38, 0)), 0.2)

				tw(p, 1.5 * T, { Size = Vector3.new(size, size, size), Transparency = 1 })
				life(p, 1.8 * T)

				if i == steps then
					ring(c + Vector3.new(0, i * R * 0.38 - R * 0.35, 0), yellow, R * 3.2, 1.2 * T, 0.15)
				end
			end)
		end

		burst(c + Vector3.new(0, R * 1.8, 0), 12, { speed = { 0.4, R * 0.8 }, life = { 1.4, 2.2 }, c0 = Color3.fromRGB(70, 58, 56), c1 = Color3.fromRGB(20, 20, 20), s0 = R * 0.4, s1 = R * 1.1, t0 = 0.3, t1 = 1, mat = Enum.Material.SmoothPlastic, up = 0.5 })
	end

	function FXV.shockwave(c, R, T)
		local cc = col(Color3.fromRGB(0, 220, 255))

		flashScreen(cc, 0.6, 0.5 * T)
		lightPulse(cc, 0.7 * T)
		shake(0.8)

		sphere(c, cc, R * 1.2, 0.3 * T, 0.2)
		sphere(c, WHITE, R * 0.8, 0.2 * T, 0)

		for i = 1, 5 do
			later((i - 1) * 0.1 * T, function()
				ring(floorPt(c), cc, R * (2.4 + i * 1.1), 0.8 * T, 0.12)
			end)
		end

		ring(c, WHITE, R * 4, 0.6 * T, 0.1, CFrame.Angles(math.pi / 2, 0, 0))
		ring(c, cc, R * 4, 0.7 * T, 0.1, CFrame.Angles(0, 0, math.pi / 2))
		burst(c, 24, { speed = { R * 2, R * 5 }, life = { 0.4, 0.8 }, c0 = WHITE, c1 = cc, s0 = 0.22, s1 = 0.03, flatY = true })
	end

	function FXV.lightning(c, R, T)
		local cc = col(Color3.fromRGB(190, 220, 255))

		flashScreen(cc, 0.5, 0.25 * T)
		lightPulse(cc, 0.5 * T)
		shake(0.7)

		sphere(c, WHITE, R * 1.2, 0.25 * T, 0)

		for i = 1, 8 do
			later((i - 1) * 0.05 * T, function()
				local top = c + Vector3.new(rng:NextNumber(-R, R), R * 4, rng:NextNumber(-R, R))

				bolt(top, c + rnd(R * 0.4), cc, R * 0.07, 0.35 * T)

				if i % 3 == 0 then
					flashScreen(WHITE, 0.7, 0.12)
				end
			end)
		end

		for _ = 1, 5 do
			bolt(c, c + rnd(R * 2), cc, R * 0.05, 0.3 * T)
		end

		burst(c, 30, { speed = { R * 1.5, R * 4 }, life = { 0.5, 1.0 }, c0 = WHITE, c1 = cc, s0 = 0.18, s1 = 0.02, drag = 1 })
	end

	function FXV.frost(c, R, T)
		local cc = col(Color3.fromRGB(140, 220, 255))

		flashScreen(cc, 0.5, 0.5 * T)
		lightPulse(cc, 0.8 * T)
		shake(0.45)

		sphere(c, cc, R * 2.2, 0.9 * T, 0.35, Enum.Material.Ice)
		ring(floorPt(c), WHITE, R * 5, 0.8 * T, 0.12)

		for _ = 1, cnt(16, 5) do
			local dir = unitRand()
			local shard = newPart(BLOCK, cc, Vector3.new(R * 0.14, R * 0.14, R * 0.6), CFrame.lookAt(c, c + dir), 0.1, Enum.Material.Ice)

			tw(shard, 1.0 * T, { CFrame = CFrame.lookAt(c + dir * R * 1.9, c + dir * R * 2.9), Transparency = 1 })
			life(shard, 1.3 * T)
		end

		burst(c, 36, { speed = { R * 0.5, R * 1.6 }, life = { 1, 2 }, c0 = WHITE, c1 = cc, s0 = 0.2, s1 = 0.03, grav = 2.5, drag = 0.5 })
	end

	function FXV.fireworks(c, R, T)
		local colors = {
			Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 210, 60), Color3.fromRGB(80, 255, 140),
			Color3.fromRGB(80, 180, 255), Color3.fromRGB(220, 100, 255), Color3.fromRGB(255, 255, 255),
		}

		flashScreen(WHITE, 0.6, 0.3 * T)
		shake(0.4)

		for i = 1, 6 do
			later((i - 1) * 0.16 * T, function()
				local cc = col(colors[((i - 1) % #colors) + 1])
				local at = c + Vector3.new(rng:NextNumber(-R, R), R * rng:NextNumber(0.8, 2.0), rng:NextNumber(-R, R))

				sphere(at, cc, R * 0.7, 0.25 * T, 0)
				lightPulse(cc, 0.4 * T)
				burst(at, 26, { speed = { R * 0.8, R * 1.7 }, life = { 0.8, 1.4 }, c0 = cc, c1 = WHITE, s0 = 0.2, s1 = 0.02, drag = 1.6, grav = 3.5 })
			end)
		end
	end

	function FXV.supernova(c, R, T)
		local base = col(Color3.fromRGB(255, 200, 120))

		flashScreen(WHITE, 0.15, 1.2 * T)
		lightPulse(base, 1.2 * T)
		shake(1)

		sphere(c, WHITE, R * 2, 0.4 * T, 0)

		for i = 1, 4 do
			later((i - 1) * 0.12 * T, function()
				local cc = FX.E.hueShift(base, i * 0.12)

				sphere(c, cc, R * (2.2 + i * 1.1), 1.1 * T, 0.3)
				ring(c, cc, R * (4 + i * 1.6), 1.0 * T, 0.12, CFrame.Angles(i * 0.5, i * 0.3, 0))
			end)
		end

		burst(c, 56, { speed = { R * 1.2, R * 4 }, life = { 0.8, 1.8 }, c0 = WHITE, c1 = base, s0 = 0.38, s1 = 0.03, drag = 0.7 })
	end

	function FXV.galaxy(c, R, T)
		local a = col(Color3.fromRGB(150, 80, 255))
		local b = col(Color3.fromRGB(70, 160, 255))

		flashScreen(a, 0.55, 0.8 * T)
		lightPulse(a, 1.3 * T)
		shake(0.5)

		sphere(c, a, R * 1.6, 1 * T, 0.5)

		for i = 1, 3 do
			ring(c, i % 2 == 0 and a or b, R * (3 + i), 1.4 * T, 0.1, CFrame.Angles(i * 0.6, i * 0.4, 0))
		end

		burst(c, 80, { speed = { R * 0.4, R * 1.5 }, life = { 1.3, 2.4 }, c0 = a, c1 = b, s0 = 0.26, s1 = 0.03, swirl = 3, grav = -1.5, flatY = false })
	end

	function FXV.toxic(c, R, T)
		local cc = col(Color3.fromRGB(100, 255, 80))

		flashScreen(cc, 0.55, 0.7 * T)
		lightPulse(cc, 1 * T)
		shake(0.45)

		sphere(c, cc, R * 2.2, 1.4 * T, 0.5)

		burst(c, 18, { speed = { 0.5, R * 1.0 }, life = { 1.8, 3 }, c0 = cc, c1 = Color3.fromRGB(30, 90, 30), s0 = R * 0.35, s1 = R * 1.0, t0 = 0.3, t1 = 1, grav = -2, up = 0.6, mat = Enum.Material.SmoothPlastic })

		for _ = 1, cnt(9, 3) do
			sphere(c + rnd(R * 0.8), cc, rng:NextNumber(0.5, 1.2), rng:NextNumber(0.8, 1.6) * T, 0.3)
		end
	end

	function FXV.confetti(c, R, T)
		local colors = {
			Color3.fromRGB(255, 70, 90), Color3.fromRGB(255, 210, 60), Color3.fromRGB(80, 255, 140),
			Color3.fromRGB(80, 180, 255), Color3.fromRGB(220, 100, 255),
		}

		flashScreen(WHITE, 0.6, 0.3 * T)
		shake(0.35)

		local cols = {}

		for i, v in ipairs(colors) do
			cols[i] = col(v)
		end

		burst(c, 60, { speed = { R * 1.2, R * 3.2 }, life = { 1.6, 2.6 }, cols = cols, s0 = 0.34, s1 = 0.3, grav = 13, drag = 0.7, up = 0.9, flat = true, t1 = 0.9, mat = Enum.Material.Neon })
	end

	function FXV.lava(c, R, T)
		local cc = col(Color3.fromRGB(255, 90, 20))

		flashScreen(cc, 0.5, 0.6 * T)
		lightPulse(cc, 1 * T)
		shake(0.8)

		sphere(c, cc, R * 2, 0.8 * T, 0.2, Enum.Material.CrackedLava)
		ring(floorPt(c), cc, R * 4.4, 0.7 * T, 0.16)

		burst(c, 14, { speed = { R * 1.6, R * 3.2 }, life = { 1.1, 1.8 }, c0 = cc, c1 = Color3.fromRGB(80, 20, 8), s0 = 0.5, s1 = 0.3, grav = 17, up = 1.1, mat = Enum.Material.CrackedLava, t1 = 0.7 })
		burst(c, 34, { speed = { R * 0.6, R * 2.4 }, life = { 0.7, 1.4 }, c0 = Color3.fromRGB(255, 220, 80), c1 = cc, s0 = 0.3, s1 = 0.03, grav = 8, up = 0.6 })
	end

	function FXV.glitch(c, R, T)
		local colors = {
			Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 0, 200), Color3.fromRGB(80, 255, 80), Color3.fromRGB(255, 255, 255),
		}

		flashScreen(Color3.fromRGB(0, 255, 255), 0.6, 0.2 * T)
		shake(0.5)

		for i = 1, cnt(20, 6) do
			local cc = col(colors[((i - 1) % #colors) + 1])
			local s = rng:NextNumber(0.3, 1.0)
			local cube = newPart(BLOCK, cc, Vector3.new(s, s, s), CFrame.new(c + rnd(R * 1.3)), 0, Enum.Material.Neon)
			local tok = st.tok

			task.spawn(function()
				for _ = 1, rng:NextInteger(3, 7) do
					if st.tok ~= tok or not cube.Parent then
						return
					end

					cube.Transparency = rng:NextNumber(0, 0.8)
					cube.Size = Vector3.new(rng:NextNumber(0.2, 1.4), rng:NextNumber(0.2, 1.4), rng:NextNumber(0.2, 1.4))
					cube.CFrame = CFrame.new(c + rnd(R * 1.3)) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0)

					if rng:NextInteger(1, 4) == 1 then
						flashScreen(cc, 0.82, 0.1)
					end

					task.wait(0.06 * T)
				end

				pcall(function()
					cube:Destroy()
				end)
			end)
		end
	end

	function FXV.vortex(c, R, T)
		local cc = col(Color3.fromRGB(120, 255, 220))

		flashScreen(cc, 0.55, 0.7 * T)
		lightPulse(cc, 1 * T)
		shake(0.45)

		for i = 1, 8 do
			later((i - 1) * 0.08 * T, function()
				ring(c + Vector3.new(0, (i - 1) * R * 0.4, 0), cc, R * (2 + (i % 3)), 1.1 * T, 0.1, CFrame.Angles(0, i * 0.7, 0))
			end)
		end

		burst(c, 56, { speed = { R * 0.5, R * 1.4 }, life = { 1.0, 1.8 }, c0 = cc, c1 = WHITE, s0 = 0.26, s1 = 0.03, grav = -9, swirl = 4, flatY = true })
	end

	local EXT = {
		classic = 2.4, blackhole = 2.3, nuke = 3.4, shockwave = 3.6, lightning = 3.0, frost = 3.0, fireworks = 3.4,
		supernova = 4.0, galaxy = 3.4, toxic = 2.6, confetti = 3.0, lava = 3.0, glitch = 2.0, vortex = 3.2,
	}

	local DUR = {
		classic = 1.8, blackhole = 4.4, nuke = 3.4, shockwave = 1.8, lightning = 1.5, frost = 2.4, fireworks = 2.8,
		supernova = 2.8, galaxy = 3.6, toxic = 3.6, confetti = 3.2, lava = 2.8, glitch = 1.8, vortex = 3.0,
	}

	local function pickFx()
		local id = Cfg.fxId or "classic"

		if id == "random" then
			local list = {}

			for _, e in ipairs(FX.FXLIST) do
				if e.id ~= "random" and e.id ~= "classic" then
					table.insert(list, e.id)
				end
			end

			id = list[rng:NextInteger(1, #list)]
		end

		return id
	end

	-- --------------------------------------------------------
	-- stage control
	-- --------------------------------------------------------
	function PV.clearFx()
		st.tok = st.tok + 1
		parts = {}
		tickers = {}

		for _, c in ipairs(fxModel:GetChildren()) do
			pcall(function()
				c:Destroy()
			end)
		end

		flashFrame.BackgroundTransparency = 1
		vp.Ambient = AMBIENT
	end

	local function showBomb(on)
		bomb.model.Parent = on and vp or nil
	end

	function PV.explode(center)
		PV.clearFx()
		showBomb(false)

		local id = pickFx()
		local sc = math.clamp((Cfg.fxSize or 100) / 100, 0.25, 4)
		local R = math.clamp(3.08 * sc ^ 0.8, 1.3, 7)
		local T = math.clamp((Cfg.fxTime or 100) / 100, 0.3, 3)
		local fn = FXV[id] or FXV.classic

		local ok, err = pcall(fn, center, R, T)

		if not ok then
			warn("[XEVRION HUB] preview effect error: " .. tostring(err))
			pcall(FXV.classic, center, R, T)
		end

		st.mode = "boom"
		st.t = 0
		st.ext = (EXT[id] or 2.6) * R
		st.boomDur = math.min((DUR[id] or 2.4) * T + 0.6, 9)

		pcall(function()
			local cf = Camera.CFrame

			FX.playSound(cf.Position + cf.LookVector * 20, id, T, 1)
		end)
	end

	function PV.boomNow()
		if not PV.active then
			return
		end

		PV.explode(Vector3.new(0, 1.35, 0))
	end

	function PV.startTest()
		if not PV.active then
			return
		end

		PV.clearFx()
		showBomb(true)

		st.mode = "fly"
		st.t = 0
		st.ext = 0
	end

	local function respawn()
		PV.clearFx()
		showBomb(true)

		st.mode = "respawn"
		st.t = 0

		local accent = (bomb.def and (bomb.def.glow or bomb.def.trail or bomb.def.color)) or CYAN

		ring(Vector3.new(0, 0.55, 0), accent, 4.5, 0.7, 0.1)
		sphere(Vector3.new(0, 0.7, 0), accent, 3.2, 0.5, 0.4)
	end

	function PV.reset()
		PV.clearFx()
		showBomb(true)

		st.mode = "idle"
		st.t = 0
		st.yaw = 0.7
		st.pitch = 0.2
		st.dist = 9.5
		st.distNow = 11
		st.camT = Vector3.new(0, 2.1, 0)
		st.shake = 0
		st.ext = 0
		st.hintGone = false

		hint.TextTransparency = 0.25

		PV.applySkin()
		PV.refreshInfo()
	end

	-- --------------------------------------------------------
	-- safe zone (character hiding + return)
	-- --------------------------------------------------------
	function PV.tpIn()
		PV.ret = nil

		local ch = LP.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")

		if not hrp or (hum and hum.Health <= 0) then
			return
		end

		PV.ret = { char = ch, cf = hrp.CFrame, anchored = hrp.Anchored }

		fade()

		pcall(function()
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			hrp.CFrame = CFrame.new(SAFE_POS) * (hrp.CFrame - hrp.CFrame.Position)
			hrp.Anchored = true
		end)
	end

	function PV.tpOut()
		local r = PV.ret

		PV.ret = nil

		if not r then
			return
		end

		local ch = LP.Character

		if ch ~= r.char then
			return
		end

		local hrp = ch:FindFirstChild("HumanoidRootPart")

		if not hrp then
			return
		end

		fade()

		pcall(function()
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			hrp.CFrame = r.cf
			hrp.Anchored = r.anchored
		end)
	end

	function PV.enter()
		if PV.active then
			return
		end

		PV.active = true
		PV.lingerUntil = 0

		pcall(PV.refreshSource, true)

		PV.tpIn()
		PV.reset()

		panel.Visible = true
	end

	function PV.leave()
		if not PV.active then
			return
		end

		PV.active = false
		PV.free = false
		PV.lingerUntil = os.clock() + 0.25
		PV.hover = false

		PV.clearFx()
		PV.tpOut()
		PV.unfit()
	end

	FX.pvForceLeave = function()
		pcall(PV.leave)
		pcall(PV.unfit)
		pcall(function()
			panel:Destroy()
			fadeFrame:Destroy()
		end)
	end

	-- --------------------------------------------------------
	-- input
	-- --------------------------------------------------------
	-- the preview title bar drags the whole block (menu + preview)
	header.InputBegan:Connect(function(input)
		if isPress(input) and not editMode then
			beginDrag("menu", input)
		end
	end)

	local dragInput = nil

	cap.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input

			if not st.hintGone then
				st.hintGone = true
			end
		end
	end)

	FX.conn(UIS.InputChanged, function(input)
		if dragInput then
			local isMouse = dragInput.UserInputType == Enum.UserInputType.MouseButton1

			if input == dragInput or (isMouse and input.UserInputType == Enum.UserInputType.MouseMovement) then
				local d = input.Delta

				st.yaw = st.yaw - d.X * 0.012
				st.pitch = math.clamp(st.pitch + d.Y * 0.008, -0.15, 1.25)
			end
		end

		if input.UserInputType == Enum.UserInputType.MouseWheel and PV.hover and PV.active then
			st.dist = math.clamp(st.dist - input.Position.Z * 0.9, 5.5, 16)
		end
	end)

	FX.conn(UIS.InputEnded, function(input)
		if dragInput then
			local isMouse = dragInput.UserInputType == Enum.UserInputType.MouseButton1

			if input == dragInput or (isMouse and input.UserInputType == Enum.UserInputType.MouseButton1) then
				dragInput = nil
			end
		end
	end)

	btnSpin.Activated:Connect(function()
		st.spin = not st.spin

		paintSpin()
	end)

	btnTest.Activated:Connect(function()
		PV.startTest()
	end)

	btnBoom.Activated:Connect(function()
		PV.boomNow()
	end)

	btnWorld.Activated:Connect(function()
		pcall(FX.previewBoom)
	end)

	LP.CharacterAdded:Connect(function()
		-- respawned while reviewing: do not teleport the new character back
		PV.ret = nil
	end)

	-- --------------------------------------------------------
	-- main loop
	-- --------------------------------------------------------
	function PV.menuHome()
		local vpS = getViewport()
		local L = layout.menu

		if L then
			return Vector2.new(L.x * vpS.X, L.y * vpS.Y)
		end

		local e = ELEMENTS.menu
		local d = e and e.defPos or UDim2.fromOffset(15, 85)

		return Vector2.new(d.X.Scale * vpS.X + d.X.Offset, d.Y.Scale * vpS.Y + d.Y.Offset)
	end

	-- FIX4: called by beginDrag so the drag starts from where the menu really is
	FX.pvSyncDrag = function(L)
		if PV.active and PV.lastMenuX and PV.lastTop then
			local vpS = getViewport()

			L.x = PV.lastMenuX / math.max(vpS.X, 1)
			L.y = PV.lastTop / math.max(vpS.Y, 1)
		end
	end

	function PV.restoreMenuPos()
		if not PV.menuMoved then
			return
		end

		PV.menuMoved = false

		local L = layout.menu

		if L then
			menu.Position = UDim2.fromScale(L.x, L.y)
		else
			local e = ELEMENTS.menu

			menu.Position = e and e.defPos or UDim2.fromOffset(15, 85)
		end
	end

	-- put the menu back to its normal size / place
	function PV.unfit()
		PV.restoreMenuPos()

		if (FX.pvFit or 1) ~= 1 then
			FX.pvFit = 1
			applyMenuAnim()
		end
	end

	-- the 3D preview always sits on the LEFT side of the menu. Menu and preview
	-- shrink a little on narrow screens and the whole block can be dragged.
	local function placePanel()
		local vpS = getViewport()
		local baseS = baseScale * scaleOf("menu")
		local fit = math.clamp((vpS.X * 0.9 - 6 * 2) / ((K.MENU_W + 6 + PW) * baseS), 0.4, 1)

		if math.abs((FX.pvFit or 1) - fit) > 0.004 then
			FX.pvFit = fit
			applyMenuAnim()
		end

		local s = baseS * fit
		local mw = K.MENU_W * s
		local pw = PW * s
		local ph = PH * s
		local gap = 6 * s
		local home = PV.menuHome()

		-- FIX4: the block used to fill ~90% of the screen, so the old limits left
		-- almost no room to move it. Once the user drags it, allow it to slide
		-- partly off-screen (a 48px strip of each part always stays visible).
		if drag and drag.id == "menu" and drag.moved then
			PV.free = true
		end

		local keep = 48 * s
		local top
		local minX
		local maxX

		if PV.free then
			top = math.clamp(home.Y, 0, math.max(0, vpS.Y - 40 * s))
			minX = 6 + gap + keep
			maxX = math.max(minX, vpS.X - keep)
		else
			top = math.clamp(home.Y, 6, math.max(6, vpS.Y - ph - 6))
			minX = 6 + pw + gap
			maxX = vpS.X - 6 - mw
		end

		local menuX = math.max(minX, math.min(home.X, maxX))
		local panelX = menuX - gap - pw

		PV.lastMenuX = menuX
		PV.lastTop = top

		panelScale.Scale = s
		panel.Position = UDim2.fromOffset(panelX, top)

		if menuX ~= home.X or top ~= home.Y then
			-- while dragging, keep the saved position inside the allowed area
			local L = layout.menu

			if L and drag and drag.id == "menu" then
				L.x = menuX / vpS.X
				L.y = top / vpS.Y
			end

			menu.Position = UDim2.fromOffset(menuX, top)
			PV.menuMoved = true
		else
			PV.restoreMenuPos()
		end
	end

	local function easeOutBack(x)
		local c1 = 1.70158
		local c3 = c1 + 1

		return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
	end

	local function updateBomb(dt)
		local now = os.clock()

		if st.mode == "idle" or st.mode == "respawn" then
			st.bobT = st.bobT + dt

			if st.spin then
				st.spinA = st.spinA + dt * 0.9
			end

			local y = 2.6 + math.sin(st.bobT * 1.8) * 0.12

			if st.mode == "respawn" then
				st.t = st.t + dt

				local u = math.clamp(st.t / 0.9, 0, 1)

				y = -1.4 + (2.6 + 1.4) * easeOutBack(u)

				if u >= 1 then
					st.mode = "idle"
				end
			end

			bombPose(CFrame.new(0, y, 0) * CFrame.Angles(0, st.spinA, 0) * CFrame.Angles(math.rad(-14), 0, 0))
			st.flyFrom = Vector3.new(0, y, 0)

			-- skin particles
			local def = bomb.def

			if def and (def.spark or def.fire or def.smoke) and st.mode == "idle" then
				st.emitAcc = st.emitAcc + dt

				if st.emitAcc > 0.06 then
					st.emitAcc = 0

					local at = Vector3.new(0, y, 0) + rnd(0.7)

					if def.fire then
						emit(at, Vector3.new(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0.8, 1.8), rng:NextNumber(-0.4, 0.4)), Color3.fromRGB(255, 210, 70), Color3.fromRGB(255, 60, 20), 0.34, 0.05, 0.6)
					elseif def.smoke then
						emit(at, Vector3.new(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0.4, 0.9), rng:NextNumber(-0.3, 0.3)), def.smoke, def.smoke, 0.4, 1.1, 1.2, { t0 = 0.35, t1 = 1, mat = Enum.Material.SmoothPlastic })
					else
						emit(at, rnd(1.2) + Vector3.new(0, 0.6, 0), def.spark, def.spark, 0.15, 0.01, 0.7)
					end
				end
			end
		elseif st.mode == "fly" then
			st.t = st.t + dt

			local FLY_T = 2.1
			local u = math.clamp(st.t / FLY_T, 0, 1)
			local tt = u ^ 1.35
			local P0 = st.flyFrom
			local P1 = Vector3.new(-6.5, 15, 2.5)
			local P2 = Vector3.new(0, 1.35, 0)
			local pos = P0 * (1 - tt) ^ 2 + P1 * (2 * (1 - tt) * tt) + P2 * (tt * tt)
			local vel = (P1 - P0) * (2 * (1 - tt)) + (P2 - P1) * (2 * tt)

			if vel.Magnitude < 0.01 then
				vel = Vector3.new(0, -1, 0)
			end

			bombPose(CFrame.lookAt(pos, pos + vel) * CFrame.Angles(0, 0, st.t * 10))

			-- trail
			local back = pos - vel.Unit * 0.9
			local def = bomb.def
			local tc = def and def.trail

			if def and def.rainbow then
				tc = Color3.fromHSV((now * 0.8) % 1, 1, 1)
			end

			if tc then
				emit(back, Vector3.new(), tc, tc, 0.4, 0.02, 0.55)
			else
				emit(back, rnd(0.4), Color3.fromRGB(190, 190, 195), Color3.fromRGB(90, 90, 96), 0.3, 0.8, 0.7, { t0 = 0.3, t1 = 1, mat = Enum.Material.SmoothPlastic })
				emit(back, rnd(0.6), Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 70, 20), 0.22, 0.02, 0.3)
			end

			if u >= 1 then
				PV.explode(P2)
				shake(0.9)
			end
		elseif st.mode == "boom" then
			st.t = st.t + dt

			if st.t >= st.boomDur then
				respawn()
			end
		end

		-- rainbow skin + aura pulse
		local def = bomb.def

		if def and def.rainbow then
			local c = Color3.fromHSV((now * 0.4) % 1, 1, 1)

			for _, h in ipairs(bomb.hull) do
				h.part.Color = c
			end

			for _, b in ipairs(bomb.bands) do
				b.Color = Color3.fromHSV((now * 0.4 + 0.5) % 1, 0.8, 1)
			end
		end

		if def and def.glow then
			bomb.aura.Transparency = 0.9 + math.sin(now * 3) * 0.04
		end
	end

	local function updateCamera(dt)
		local goal = st.dist
		local tgt = Vector3.new(0, 2.1, 0)

		if st.mode == "fly" then
			goal = goal + 3.5
			tgt = tgt:Lerp(bomb.model:GetPivot().Position, 0.5)
		elseif st.mode == "boom" then
			goal = goal + st.ext * 0.55
			tgt = Vector3.new(0, 2.1 + st.ext * 0.22, 0)

			if not dragInput then
				st.yaw = st.yaw + dt * 0.18
			end
		end

		local k = 1 - math.exp(-dt * 4)

		st.distNow = st.distNow + (goal - st.distNow) * k
		st.camT = st.camT:Lerp(tgt, k)

		local cp, sp = math.cos(st.pitch), math.sin(st.pitch)
		local dir = Vector3.new(cp * math.sin(st.yaw), sp, cp * math.cos(st.yaw))
		local off = Vector3.zero

		if st.shake > 0.01 then
			off = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)) * st.shake * 0.28
			st.shake = math.max(0, st.shake - dt * 1.5)
		end

		cam.CFrame = CFrame.lookAt(st.camT + dir * st.distNow + off, st.camT + off)
	end

	local lastPoll = 0

	FX.conn(RunService.RenderStepped, function(dt)
		local now = os.clock()

		-- when should the preview be open: menu open + on the VISUAL tab page
		local want = menuVisible and not editMode and not droneActive and FX.page == "menu" and FX.tab == 7

		if want ~= PV.active then
			if want then
				PV.enter()
			else
				PV.leave()
			end
		end

		local showing = PV.active or now < PV.lingerUntil

		if panel.Visible ~= showing then
			panel.Visible = showing
		end

		if not showing then
			PV.unfit()

			return
		end

		placePanel()

		if not PV.active then
			return
		end

		-- watch the picks (skin / effect / size / time / color)
		local last = st.last

		if now - lastPoll > 0.08 then
			lastPoll = now

			if now - (PV.srcT or 0) > 0.6 then
				PV.srcT = now
				pcall(PV.refreshSource)
			end

			if last.skinId ~= Cfg.skinId or last.skinCustom ~= Cfg.skinCustom then
				last.skinId = Cfg.skinId
				last.skinCustom = Cfg.skinCustom
				PV.applySkin()
			end

			if last.fxId ~= Cfg.fxId then
				local first = last.fxId == nil

				last.fxId = Cfg.fxId
				PV.refreshInfo()

				if not first then
					PV.boomNow()
				end
			end

			if last.fxSize ~= Cfg.fxSize or last.fxTime ~= Cfg.fxTime or last.fxColor ~= Cfg.fxColor then
				local first = last.fxSize == nil

				last.fxSize = Cfg.fxSize
				last.fxTime = Cfg.fxTime
				last.fxColor = Cfg.fxColor

				if not first then
					st.pendingBoom = now + 0.35
				end
			end

			if st.pendingBoom and now >= st.pendingBoom then
				st.pendingBoom = nil
				PV.boomNow()
			end

			if st.hintGone and hint.TextTransparency < 1 then
				hint.TextTransparency = math.min(1, hint.TextTransparency + 0.2)
			end
		end

		dt = math.min(dt, 0.1)

		updateBomb(dt)
		stepParticles(dt)
		stepTickers(dt)
		updateCamera(dt)

		for i, r in ipairs(floorRings) do
			r.Transparency = 0.6 + 0.22 * math.sin(now * 2.2 - i * 0.9)
		end

		for _, s in ipairs(twinkle) do
			s.p.Transparency = 0.35 + 0.4 * math.sin(now * s.sp + s.ph)
		end
	end)
end

local PX_PER_DEG = 7
local TAPE_ROW = 22
local HDG_PX = 24
local HDG_NAMES = { [0] = "N", [90] = "E", [180] = "S", [270] = "W" }

local hud = Instance.new("Frame")
hud.Name = "HUD"
hud.Size = UDim2.fromScale(1, 1)
hud.BackgroundTransparency = 1
hud.Visible = false
hud.Parent = gui

local function hudText(parent, text, size, pos, align)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = size
	t.Position = pos or UDim2.new()
	t.Text = text or ""
	t.TextColor3 = HUD_GREEN
	t.TextSize = 13
	t.Font = Enum.Font.Code
	t.TextXAlignment = align or Enum.TextXAlignment.Left
	t.TextStrokeTransparency = 0.5
	t.Parent = parent
	return t
end

local hudStyles = {}

local function hudShopColor(color)
	if color == THEME.Danger or color == THEME.ErrorBase then
		return SHOP.Red
	elseif color == THEME.Warn then
		return SHOP.Gold
	elseif color == THEME.Muted then
		return Color3.fromRGB(96, 100, 114)
	elseif color == THEME.Cyan then
		return SHOP.Blue
	end

	return SHOP.Green
end

function FX.hudPaint(b, color)
	local st = hudStyles[b]

	if not st then
		return
	end

	local c = hudShopColor(color)
	local edge = shopEdge(c)

	st.Base = c

	tween(b, 0.2, { BackgroundColor3 = c })
	tween(st.Stroke, 0.2, { Color = edge })
	tween(st.TextStroke, 0.2, { Color = edge })
end

local function makeHudButton(parent, text, size, pos, anchor, color, onClick)
	local c0 = hudShopColor(color)
	local edge = shopEdge(c0)

	local b = Instance.new("TextButton")
	b.Size = size
	b.AnchorPoint = anchor
	b.Position = pos
	b.BackgroundColor3 = c0
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	if type(text) == "table" then
		FX.tr(b, text.key)
	else
		b.Text = text
	end
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 13
	b.Font = Enum.Font.FredokaOne
	b.Parent = parent

	addCorner(b, 8)

	local s = addStroke(b, edge, 2, 0)

	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205))
	g.Rotation = 90
	g.Parent = b

	local ts = addStroke(b, edge, 1.5, 0)
	ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

	local st = { Base = c0, Stroke = s, TextStroke = ts }

	hudStyles[b] = st

	b.MouseEnter:Connect(function()
		playUI("Hover")
		tween(b, 0.15, { BackgroundColor3 = st.Base:Lerp(Color3.new(1, 1, 1), 0.15) })
	end)

	b.MouseLeave:Connect(function()
		tween(b, 0.2, { BackgroundColor3 = st.Base })
	end)

	b.MouseButton1Down:Connect(function()
		tween(b, 0.08, { BackgroundColor3 = st.Base:Lerp(Color3.new(0, 0, 0), 0.2) })
	end)

	b.MouseButton1Up:Connect(function()
		tween(b, 0.2, { BackgroundColor3 = st.Base })
	end)

	b.Activated:Connect(function()
		playUI("Click")
		onClick()
	end)

	return b, s
end

local ladder = Instance.new("Frame")
ladder.Name = "PitchLadder"
ladder.Size = UDim2.fromOffset(1, 1)
ladder.AnchorPoint = Vector2.new(0.5, 0.5)
ladder.Position = UDim2.fromScale(0.5, 0.5)
ladder.BackgroundTransparency = 1
ladder.Parent = hud

for a = -30, 30, 10 do
	local width = a == 0 and 240 or (a % 20 == 0 and 110 or 60)

	local rung = Instance.new("Frame")
	rung.Size = UDim2.fromOffset(width, 2)
	rung.AnchorPoint = Vector2.new(0.5, 0.5)
	rung.Position = UDim2.fromOffset(0, -a * PX_PER_DEG)
	rung.BackgroundColor3 = HUD_GREEN
	rung.BackgroundTransparency = a == 0 and 0.1 or 0.4
	rung.BorderSizePixel = 0
	rung.Parent = ladder

	if a ~= 0 then
		local txt = (a > 0 and "+" or "") .. tostring(a)
		local lbl = hudText(rung, txt, UDim2.fromOffset(40, 14), UDim2.new(0, -46, 0.5, -7), Enum.TextXAlignment.Right)
		lbl.TextSize = 11
		local lbl2 = hudText(rung, txt, UDim2.fromOffset(40, 14), UDim2.new(1, 6, 0.5, -7))
		lbl2.TextSize = 11
	end
end

local RET_SIZE = 84

local function makeBrackets(parent, len, thick, color)
	local list = {}

	local function bar(sz, pos)
		local f = Instance.new("Frame")
		f.Size = sz
		f.Position = pos
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.Parent = parent
		table.insert(list, f)
	end

	bar(UDim2.fromOffset(len, thick), UDim2.fromOffset(0, 0))
	bar(UDim2.fromOffset(thick, len), UDim2.fromOffset(0, 0))
	bar(UDim2.fromOffset(len, thick), UDim2.new(1, -len, 0, 0))
	bar(UDim2.fromOffset(thick, len), UDim2.new(1, -thick, 0, 0))
	bar(UDim2.fromOffset(len, thick), UDim2.new(0, 0, 1, -thick))
	bar(UDim2.fromOffset(thick, len), UDim2.new(0, 0, 1, -len))
	bar(UDim2.fromOffset(len, thick), UDim2.new(1, -len, 1, -thick))
	bar(UDim2.fromOffset(thick, len), UDim2.new(1, -thick, 1, -len))

	return list
end

local lockGui = Instance.new("ScreenGui")
lockGui.Name = "DroneLockReticle"
lockGui.ResetOnSpawn = false
lockGui.IgnoreGuiInset = true
lockGui.DisplayOrder = 5
lockGui.Enabled = false
lockGui.Parent = PlayerGui

local reticle = Instance.new("Frame")
reticle.Name = "Reticle"
reticle.Size = UDim2.fromOffset(RET_SIZE, RET_SIZE)
reticle.AnchorPoint = Vector2.new(0.5, 0.5)
reticle.Position = UDim2.fromScale(0.5, 0.5)
reticle.BackgroundTransparency = 1
reticle.Parent = lockGui

local reticleBars = makeBrackets(reticle, 16, 2, HUD_GREEN)
local reticleColor = HUD_GREEN

local lockLabel = hudText(reticle, "", UDim2.fromOffset(200, 16), UDim2.new(0.5, -100, 1, 6), Enum.TextXAlignment.Center)
lockLabel.TextColor3 = THEME.Danger

local function setReticleColor(c)
	if c == reticleColor then
		return
	end

	reticleColor = c

	for _, bar in ipairs(reticleBars) do
		bar.BackgroundColor3 = c
	end

	lockLabel.TextColor3 = c
end

do
	local fxGui = Instance.new("ScreenGui")
	fxGui.Name = "DroneSpeedFx"
	fxGui.ResetOnSpawn = false
	fxGui.IgnoreGuiInset = true
	fxGui.DisplayOrder = -1
	fxGui.Enabled = false
	fxGui.Parent = PlayerGui

	FX.fxGui = fxGui

	local layer = Instance.new("Frame")
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.BorderSizePixel = 0
	layer.ClipsDescendants = true
	layer.Parent = fxGui

	FX.lines = {}

	local COUNT = 18

	for i = 1, COUNT do
		local holder = Instance.new("Frame")
		holder.Size = UDim2.fromScale(1, 1)
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0
		holder.Rotation = (i - 1) * (360 / COUNT) + math.random() * 8
		holder.Parent = layer

		local line = Instance.new("Frame")
		line.Size = UDim2.fromOffset(80, 2)
		line.AnchorPoint = Vector2.new(0, 0.5)
		line.Position = UDim2.new(0.5, 300, 0.5, 0)
		line.BackgroundColor3 = Color3.fromRGB(225, 240, 255)
		line.BackgroundTransparency = 1
		line.BorderSizePixel = 0
		line.Parent = holder

		local fade = Instance.new("UIGradient")
		fade.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		fade.Parent = line

		FX.lines[i] = {
			line = line,
			phase = math.random(),
			len = 50 + math.random() * 110,
			spd = 0.85 + math.random() * 0.8,
		}
	end
end

function FX.updateLines(dt)
	local k = FX.speedK
	local on = k > 0.04

	if on ~= FX.linesOn then
		FX.linesOn = on
		FX.fxGui.Enabled = on
	end

	if not on then
		return
	end

	FX.lt += dt * (0.7 + 1.8 * k)

	local vp = Camera.ViewportSize
	local r0 = math.min(vp.X, vp.Y) * 0.30
	local r1 = math.sqrt(vp.X * vp.X + vp.Y * vp.Y) * 0.5 + 40

	for _, L in ipairs(FX.lines) do
		local p = (FX.lt * L.spd + L.phase) % 1
		local d = r0 + (r1 - r0) * (p * p)
		local len = L.len * (0.4 + 1.2 * p) * (0.5 + k)

		L.line.Size = UDim2.fromOffset(len, 2)
		L.line.Position = UDim2.new(0.5, d, 0.5, 0)
		L.line.BackgroundTransparency = 1 - 0.55 * k * math.sin(p * math.pi)
	end
end

do
	local aimDot = Instance.new("Frame")
	aimDot.Size = UDim2.fromOffset(4, 4)
	aimDot.AnchorPoint = Vector2.new(0.5, 0.5)
	aimDot.Position = UDim2.fromScale(0.5, 0.5)
	aimDot.BackgroundColor3 = HUD_GREEN
	aimDot.BorderSizePixel = 0
	aimDot.Parent = hud

	addCorner(aimDot, 2)
end

local hdgGroup = Instance.new("Frame")
hdgGroup.Name = "Heading"
hdgGroup.Size = UDim2.fromOffset(300, 70)
hdgGroup.AnchorPoint = Vector2.new(0.5, 0)
hdgGroup.Position = UDim2.new(0.5, 0, 0, 14)
hdgGroup.BackgroundTransparency = 1
hdgGroup.Parent = hud

local headingTicks = {}

do
	local headingBox = Instance.new("Frame")
	headingBox.Size = UDim2.fromOffset(300, 28)
	headingBox.Position = UDim2.fromOffset(0, 0)
	headingBox.BackgroundTransparency = 1
	headingBox.ClipsDescendants = true
	headingBox.Parent = hdgGroup

	for i = 1, 29 do
		local t = hudText(headingBox, "", UDim2.fromOffset(40, 20), UDim2.new(0.5, 0, 0.5, 0), Enum.TextXAlignment.Center)
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		headingTicks[i] = t
	end
end

hudText(hdgGroup, "▼", UDim2.fromOffset(20, 12), UDim2.new(0.5, -10, 0, 26), Enum.TextXAlignment.Center)

local headingReadout = hudText(hdgGroup, "", UDim2.fromOffset(120, 18), UDim2.new(0.5, -60, 0, 38), Enum.TextXAlignment.Center)
headingReadout.TextSize = 14

register("heading", "HEADING", hdgGroup)

local telemetry = hudText(hud, "", UDim2.fromOffset(260, 110), UDim2.fromOffset(16, 14))
telemetry.TextYAlignment = Enum.TextYAlignment.Top
telemetry.TextSize = 12

register("telemetry", "TELEMETRY", telemetry)

local function createVerticalTape(parent, position, prefix, step)
	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(78, 240)
	box.Position = position
	box.BackgroundTransparency = 1
	box.ClipsDescendants = true
	box.Parent = parent

	local ticks = {}

	for i = 1, 13 do
		local t = hudText(box, "", UDim2.new(1, 0, 0, TAPE_ROW), UDim2.new(0, 0, 0.5, 0), Enum.TextXAlignment.Center)
		t.AnchorPoint = Vector2.new(0, 0.5)
		t.TextSize = 12
		ticks[i] = t
	end

	local readout = Instance.new("Frame")
	readout.Size = UDim2.new(1, 0, 0, 26)
	readout.AnchorPoint = Vector2.new(0, 0.5)
	readout.Position = UDim2.new(0, 0, 0.5, 0)
	readout.BackgroundColor3 = HUD_DARK
	readout.BackgroundTransparency = 0.15
	readout.BorderSizePixel = 0
	readout.Parent = box

	addStroke(readout, HUD_GREEN, 1.2, 0.2)

	local readoutText = hudText(readout, "", UDim2.fromScale(1, 1), UDim2.new(), Enum.TextXAlignment.Center)
	readoutText.TextSize = 14

	local function update(value)
		local base = math.floor(value / step) * step

		for i, t in ipairs(ticks) do
			local v = base + (i - 7) * step
			t.Text = tostring(math.floor(v))
			t.Position = UDim2.new(0, 0, 0.5, -(v - value) / step * TAPE_ROW)
		end

		readoutText.Text = string.format("%s %d", prefix, math.floor(value))
	end

	return update, box
end

local updateSpeedTape, speedBox = createVerticalTape(hud, UDim2.new(0, 16, 0.5, -120), "SPD", K.SPEED_STEP)
local updateAltTape, altBox = createVerticalTape(hud, UDim2.new(1, -94, 0.5, -120), "ALT", 20)

register("speedTape", "SPEED TAPE", speedBox)
register("altTape", "ALTITUDE", altBox)

local function updateHeadingTape(heading)
	local base = math.floor(heading / 10) * 10

	for i = 1, 29 do
		local v = base + (i - 15) * 10
		local deg = math.floor(v) % 360
		local t = headingTicks[i]

		if HDG_NAMES[deg] then
			t.Text = HDG_NAMES[deg]
		elseif deg % 30 == 0 then
			t.Text = string.format("%03d", deg)
		else
			t.Text = "|"
		end

		t.Position = UDim2.new(0.5, (v - heading) / 10 * HDG_PX, 0.5, 0)
	end
end

local messageLabel = hudText(hud, "", UDim2.fromOffset(380, 20), UDim2.new(0.5, -190, 0, 72), Enum.TextXAlignment.Center)
messageLabel.TextSize = 14

function showMessage(text, color)
	messageLabel.Text = text
	messageLabel.TextColor3 = color or HUD_GREEN
	messageUntil = os.clock() + 2.5
end

do
	local ejectButton = makeHudButton(
		hud,
		{ key = "eject" },
		UDim2.fromOffset(104, 34),
		UDim2.new(1, -16, 0, 14),
		Vector2.new(1, 0),
		THEME.Danger,
		function()
			stopDrone()
		end
	)

	register("eject", "EJECT", ejectButton)
end

local bottomGroup = Instance.new("Frame")
bottomGroup.Name = "BottomBar"
bottomGroup.Size = UDim2.fromOffset(300, 100)
bottomGroup.AnchorPoint = Vector2.new(0.5, 1)
bottomGroup.Position = UDim2.new(0.5, 0, 1, -10)
bottomGroup.BackgroundTransparency = 1
bottomGroup.Parent = hud

makeHudButton(
	bottomGroup,
	"−",
	UDim2.fromOffset(44, 34),
	UDim2.new(0.5, -96, 1, -56),
	Vector2.new(0.5, 1),
	HUD_GREEN,
	function()
		changeSpeed(-K.SPEED_STEP)
	end
)

local speedReadoutText

do
	local speedReadout = Instance.new("Frame")
	speedReadout.Size = UDim2.fromOffset(96, 34)
	speedReadout.AnchorPoint = Vector2.new(0.5, 1)
	speedReadout.Position = UDim2.new(0.5, 0, 1, -56)
	speedReadout.BackgroundColor3 = Color3.fromRGB(38, 40, 48)
	speedReadout.BackgroundTransparency = 0
	speedReadout.BorderSizePixel = 0
	speedReadout.Parent = bottomGroup

	addCorner(speedReadout, 8)
	addStroke(speedReadout, SHOP.Dark, 2, 0)

	speedReadoutText = hudText(speedReadout, "", UDim2.fromScale(1, 1), UDim2.new(), Enum.TextXAlignment.Center)
	speedReadoutText.TextSize = 14
	speedReadoutText.Font = Enum.Font.GothamBold
end

makeHudButton(
	bottomGroup,
	"+",
	UDim2.fromOffset(44, 34),
	UDim2.new(0.5, 96, 1, -56),
	Vector2.new(0.5, 1),
	HUD_GREEN,
	function()
		changeSpeed(K.SPEED_STEP)
	end
)

local lockButton, lockStroke = makeHudButton(
	bottomGroup,
	FX.L("lock_off"),
	UDim2.fromOffset(150, 40),
	UDim2.new(0.5, 0, 1, -6),
	Vector2.new(0.5, 1),
	HUD_GREEN,
	function()
		setLock(not lockEnabled)
	end
)

register("bottom", "SPEED / LOCK", bottomGroup)

do
	local nextButton = makeHudButton(
		hud,
		{ key = "next" },
		UDim2.fromOffset(96, 40),
		UDim2.new(0.5, 90, 1, -16),
		Vector2.new(0, 1),
		THEME.Cyan,
		function()
			FX.cycleTarget()
		end
	)

	register("next", "NEXT TARGET", nextButton)
end

do
	local boostButton, boostStroke = makeHudButton(
		hud,
		FX.L("boost"),
		UDim2.fromOffset(96, 40),
		UDim2.new(0.5, -90, 1, -16),
		Vector2.new(1, 1),
		THEME.Warn,
		function()
			FX.doBoost()
		end
	)

	FX.boostButton = boostButton
	FX.boostStroke = boostStroke

	register("boost", "BOOST", boostButton)
end

function FX.updateBoostUI(now)
	local btn = FX.boostButton

	if not btn then
		return
	end

	local text, color, bg

	if now < FX.boostUntil then
		text = FX.L("boost") .. " ▲"
		color = THEME.Danger
		bg = 0.05
	elseif now < FX.boostReadyAt then
		text = FX.L("boost") .. " " .. math.ceil(FX.boostReadyAt - now) .. "s"
		color = THEME.Muted
		bg = 0.5
	else
		text = FX.L("boost")
		color = THEME.Warn
		bg = 0.25
	end

	if text ~= FX.boostText then
		FX.boostText = text
		btn.Text = text
		FX.hudPaint(btn, color)
	end
end

function refreshLockUI()
	lockButton.Text = lockEnabled and FX.L("lock_on") or FX.L("lock_off")
	local c = lockEnabled and THEME.Danger or HUD_GREEN
	FX.hudPaint(lockButton, c)
end

do
	local W = 260
	local FULL_H = 184
	local BAR_H = 28
	local topLeft = Vector2.new(0, 0)

	local panel = Instance.new("Frame")
	panel.Name = "SwarmPanel"
	panel.Size = UDim2.fromOffset(W, FULL_H)
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -14, 0.25, 0)
	panel.BackgroundColor3 = Color3.fromRGB(60, 62, 72)
	panel.BackgroundTransparency = 0
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui

	addCorner(panel, 10)
	addStroke(panel, SHOP.Dark, 3, 0)

	local bar = Instance.new("Frame")
	bar.Name = "TitleBar"
	bar.Size = UDim2.fromOffset(W, BAR_H)
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.BackgroundTransparency = 0
	bar.BorderSizePixel = 0
	bar.Active = true
	bar.Parent = panel

	addCorner(bar, 8)

	local barGradient = Instance.new("UIGradient")
	barGradient.Color = ColorSequence.new(Color3.fromRGB(255, 228, 118), Color3.fromRGB(245, 178, 46))
	barGradient.Rotation = 90
	barGradient.Parent = bar

	bar.InputBegan:Connect(function(input)
		if isPress(input) then
			beginDrag("swarm", input)
		end
	end)

	SW.titleLabel = hudText(bar, "", UDim2.fromOffset(166, BAR_H), UDim2.fromOffset(8, 0))
	SW.titleLabel.Font = Enum.Font.FredokaOne
	SW.titleLabel.TextSize = 12
	SW.titleLabel.TextColor3 = Color3.new(1, 1, 1)
	SW.titleLabel.TextStrokeColor3 = SHOP.Dark
	SW.titleLabel.TextStrokeTransparency = 0

	makeHudButton(bar, "−", UDim2.fromOffset(24, 22), UDim2.fromOffset(176, 3), topLeft, THEME.Cyan, function()
		SW.resize(-0.1)
	end)

	makeHudButton(bar, "+", UDim2.fromOffset(24, 22), UDim2.fromOffset(203, 3), topLeft, THEME.Cyan, function()
		SW.resize(0.1)
	end)

	SW.collapseBtn = makeHudButton(bar, "▲", UDim2.fromOffset(24, 22), UDim2.fromOffset(230, 3), topLeft, THEME.Warn, function()
		Cfg.swarmCollapsed = not Cfg.swarmCollapsed
		SW.applyCollapse()
		scheduleSave()
	end)

	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.Position = UDim2.fromOffset(0, BAR_H)
	inner.Size = UDim2.fromOffset(W, FULL_H - BAR_H)
	inner.BackgroundTransparency = 1
	inner.Parent = panel

	SW.msgLabel = hudText(inner, "", UDim2.fromOffset(244, 14), UDim2.fromOffset(8, 2))
	SW.msgLabel.TextSize = 12

	SW.tgtLabel = hudText(inner, "", UDim2.fromOffset(244, 14), UDim2.fromOffset(8, 18))
	SW.tgtLabel.TextSize = 12
	SW.tgtLabel.TextColor3 = THEME.Muted

	SW.lockBtn, SW.lockStroke = makeHudButton(
		inner,
		FX.L("lock_off"),
		UDim2.fromOffset(120, 32),
		UDim2.fromOffset(8, 38),
		topLeft,
		HUD_GREEN,
		function()
			if SW.onLock then
				SW.onLock()
			end
		end
	)

	makeHudButton(
		inner,
		{ key = "next" },
		UDim2.fromOffset(120, 32),
		UDim2.fromOffset(132, 38),
		topLeft,
		THEME.Cyan,
		function()
			if SW.onNext then
				SW.onNext()
			end
		end
	)

	makeHudButton(
		inner,
		{ key = "sw_add" },
		UDim2.fromOffset(120, 32),
		UDim2.fromOffset(8, 76),
		topLeft,
		THEME.Accent,
		function()
			if SW.onAdd then
				SW.onAdd()
			end
		end
	)

	makeHudButton(
		inner,
		{ key = "sw_clear" },
		UDim2.fromOffset(120, 32),
		UDim2.fromOffset(132, 76),
		topLeft,
		THEME.Warn,
		function()
			if SW.onClear then
				SW.onClear()
			end
		end
	)

	SW.launchBtn, SW.launchStroke = makeHudButton(
		inner,
		{ key = "sw_launch" },
		UDim2.fromOffset(244, 38),
		UDim2.fromOffset(8, 114),
		topLeft,
		THEME.Danger,
		function()
			if SW.onLaunch then
				SW.onLaunch()
			end
		end
	)

	SW.panel = panel
	SW.inner = inner

	function SW.applyCollapse()
		local c = Cfg.swarmCollapsed == true

		inner.Visible = not c
		panel.Size = UDim2.fromOffset(W, c and BAR_H or FULL_H)
		SW.collapseBtn.Text = c and "▼" or "▲"
	end

	function SW.resize(delta)
		local L = ensureLayout("swarm")

		L.s = math.clamp(
			math.floor((scaleOf("swarm") + delta) / K.SCALE_STEP + 0.5) * K.SCALE_STEP,
			K.MIN_LAYOUT_SCALE,
			K.MAX_LAYOUT_SCALE
		)

		applyElement("swarm")
		scheduleSave()
	end

	register("swarm", "SWARM PANEL", panel)
	SW.applyCollapse()
end

local controls = Instance.new("Frame")
controls.Name = "DirectionPad"
controls.Size = UDim2.fromOffset(202, 128)
controls.AnchorPoint = Vector2.new(0, 1)
controls.Position = UDim2.new(0, 30, 1, -24)
controls.BackgroundTransparency = 1
controls.Parent = hud

register("pad", "DIRECTION PAD", controls)

local function createMoveButton(text, pos)
	local b = Instance.new("TextButton")

	b.Size = UDim2.fromOffset(58, 58)
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = pos
	b.BackgroundColor3 = SHOP.Blue
	b.BackgroundTransparency = 0
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 25
	b.Font = Enum.Font.FredokaOne
	b.AutoButtonColor = false
	b.Parent = controls

	addCorner(b, 14)

	local s = addStroke(b, shopEdge(SHOP.Blue), 2, 0)

	local dg = Instance.new("UIGradient")
	dg.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205))
	dg.Rotation = 90
	dg.Parent = b

	local dts = addStroke(b, shopEdge(SHOP.Blue), 1.5, 0)
	dts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

	local sc = Instance.new("UIScale")
	sc.Parent = b

	local function pressed()
		tween(sc, 0.08, { Scale = 0.9 })
		tween(b, 0.08, { BackgroundColor3 = SHOP.Blue:Lerp(Color3.new(0, 0, 0), 0.25) })
	end

	local function released()
		tween(sc, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(b, 0.2, { BackgroundColor3 = SHOP.Blue })
	end

	b.InputBegan:Connect(function(input)
		if isPress(input) then
			pressed()
		end
	end)

	b.InputEnded:Connect(function(input)
		if isPress(input) then
			released()
		end
	end)

	return b
end

local upButton = createMoveButton("▲", UDim2.fromOffset(72 + 29, 0 + 29))
local downButton = createMoveButton("▼", UDim2.fromOffset(72 + 29, 70 + 29))
local leftButton = createMoveButton("◀", UDim2.fromOffset(0 + 29, 70 + 29))
local rightButton = createMoveButton("▶", UDim2.fromOffset(144 + 29, 70 + 29))

local radar = Instance.new("Frame")
radar.Name = "Radar"
radar.Size = UDim2.fromOffset(K.RADAR_SIZE, K.RADAR_SIZE)
radar.AnchorPoint = Vector2.new(1, 1)
radar.Position = UDim2.new(1, -16, 1, -16)
radar.BackgroundColor3 = HUD_DARK
radar.BackgroundTransparency = 0.25
radar.BorderSizePixel = 0
radar.ClipsDescendants = true
radar.Parent = hud

addCorner(radar, K.RADAR_SIZE / 2)
addStroke(radar, HUD_GREEN, 1.5, 0.3)

do
	local function makeRing(frac)
		local ring = Instance.new("Frame")
		ring.Size = UDim2.fromScale(frac, frac)
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0.5)
		ring.BackgroundTransparency = 1
		ring.BorderSizePixel = 0
		ring.Parent = radar

		addCorner(ring, K.RADAR_SIZE)
		addStroke(ring, HUD_GREEN, 1, 0.6)
	end

	makeRing(0.5)
	makeRing(0.98)

	local crossH = Instance.new("Frame")
	crossH.Size = UDim2.new(1, 0, 0, 1)
	crossH.AnchorPoint = Vector2.new(0.5, 0.5)
	crossH.Position = UDim2.fromScale(0.5, 0.5)
	crossH.BackgroundColor3 = HUD_GREEN
	crossH.BackgroundTransparency = 0.7
	crossH.BorderSizePixel = 0
	crossH.Parent = radar

	local crossV = Instance.new("Frame")
	crossV.Size = UDim2.new(0, 1, 1, 0)
	crossV.AnchorPoint = Vector2.new(0.5, 0.5)
	crossV.Position = UDim2.fromScale(0.5, 0.5)
	crossV.BackgroundColor3 = HUD_GREEN
	crossV.BackgroundTransparency = 0.7
	crossV.BorderSizePixel = 0
	crossV.Parent = radar

	local ownShip = Instance.new("Frame")
	ownShip.Size = UDim2.fromOffset(6, 6)
	ownShip.AnchorPoint = Vector2.new(0.5, 0.5)
	ownShip.Position = UDim2.fromScale(0.5, 0.5)
	ownShip.BackgroundColor3 = Color3.new(1, 1, 1)
	ownShip.BorderSizePixel = 0
	ownShip.ZIndex = 5
	ownShip.Parent = radar

	addCorner(ownShip, 3)

	local radarLabel = hudText(radar, "RADAR", UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 4), Enum.TextXAlignment.Center)
	radarLabel.TextSize = 10
	radarLabel.ZIndex = 6

	local radarRangeLabel = hudText(radar, string.format(FX.L("rng") .. " %d ST", Cfg.radarRange), UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 1, -18), Enum.TextXAlignment.Center)
	radarRangeLabel.TextSize = 10
	radarRangeLabel.ZIndex = 6

	FX.rangeLabel = radarRangeLabel
end

function FX.cycleRadar()
	local list = FX.RADAR_RANGES
	local idx = table.find(list, Cfg.radarRange) or 1

	Cfg.radarRange = list[idx % #list + 1]
	FX.rangeLabel.Text = string.format(FX.L("rng") .. " %d ST", Cfg.radarRange)

	showMessage(FX.L("m_radar") .. " " .. Cfg.radarRange, HUD_GREEN)
	playUI("Click")
	scheduleSave()
end

do
	local radarTap = Instance.new("TextButton")
	radarTap.Name = "RangeTap"
	radarTap.Size = UDim2.fromScale(1, 1)
	radarTap.BackgroundTransparency = 1
	radarTap.Text = ""
	radarTap.AutoButtonColor = false
	radarTap.ZIndex = 8
	radarTap.Parent = radar

	radarTap.Activated:Connect(function()
		FX.cycleRadar()
	end)
end

local sweepHolders = {}

for k = 0, K.TRAIL_COUNT do
	local holder = Instance.new("Frame")
	holder.Name = "Sweep" .. k
	holder.Size = UDim2.fromScale(1, 1)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Parent = radar

	local line = Instance.new("Frame")
	line.Size = UDim2.new(0.5, 0, 0, 2)
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Position = UDim2.new(0.5, 0, 0.5, 0)
	line.BackgroundColor3 = HUD_GREEN
	line.BackgroundTransparency = k == 0 and 0.15 or math.min(0.4 + k * 0.12, 0.95)
	line.BorderSizePixel = 0
	line.Parent = holder

	sweepHolders[k] = holder
end

local radarDots = {}

for i = 1, 30 do
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(7, 7)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.BackgroundColor3 = THEME.Cyan
	dot.BorderSizePixel = 0
	dot.Visible = false
	dot.ZIndex = 4
	dot.Parent = radar

	addCorner(dot, 4)
	radarDots[i] = dot
end

local radarBlips = {}
local radarBlipCount = 0

register("radar", "RADAR", radar)

do
	local INFO_W = 200
	local INFO_H = 58
	local HOME_X = 0.5
	local HOME_Y = 0.3
	local GAP = 42

	local card = Instance.new("Frame")
	card.Name = "TargetInfo"
	card.Size = UDim2.fromOffset(INFO_W, INFO_H)
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = UDim2.fromScale(HOME_X, HOME_Y)
	card.BackgroundColor3 = HUD_DARK
	card.BackgroundTransparency = 0.2
	card.BorderSizePixel = 0
	card.Visible = false
	card.Parent = hud

	addCorner(card, 8)
	addStroke(card, THEME.Danger, 1.5, 0.2)

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.fromOffset(44, 44)
	avatar.Position = UDim2.fromOffset(7, 7)
	avatar.BackgroundColor3 = THEME.Track
	avatar.BorderSizePixel = 0
	avatar.Image = ""
	avatar.ScaleType = Enum.ScaleType.Crop
	avatar.Parent = card

	addCorner(avatar, 8)

	local fallback = hudText(avatar, "?", UDim2.fromScale(1, 1), UDim2.new(), Enum.TextXAlignment.Center)
	fallback.TextSize = 20
	fallback.Font = Enum.Font.GothamBold
	fallback.TextColor3 = THEME.Muted
	fallback.Visible = false

	local infoName = hudText(card, "", UDim2.fromOffset(136, 20), UDim2.fromOffset(58, 8))
	infoName.Font = Enum.Font.GothamBold
	infoName.TextSize = 14
	infoName.TextColor3 = THEME.Text
	infoName.TextTruncate = Enum.TextTruncate.AtEnd

	local infoUser = hudText(card, "", UDim2.fromOffset(136, 18), UDim2.fromOffset(58, 30))
	infoUser.Font = Enum.Font.GothamMedium
	infoUser.TextSize = 12
	infoUser.TextColor3 = THEME.Cyan
	infoUser.TextTruncate = Enum.TextTruncate.AtEnd

	local arrow = hudText(card, "▼", UDim2.fromOffset(16, 12), UDim2.new(0.5, -8, 1, -1), Enum.TextXAlignment.Center)
	arrow.TextSize = 11
	arrow.TextColor3 = THEME.Danger

	register("targetInfo", "TARGET INFO", card)

	local shownRoot = nil

	local function showPlayer(plr)
		infoName.Text = plr.DisplayName
		infoUser.Text = "@" .. plr.Name
		avatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", plr.UserId)
		fallback.Visible = false
	end

	local function populate(root)
		shownRoot = root

		local model = root.Parent
		local plr = model and Players:GetPlayerFromCharacter(model)

		if plr then
			showPlayer(plr)
		else
			local hum = model and model:FindFirstChildOfClass("Humanoid")
			local shown = hum and hum.DisplayName ~= "" and hum.DisplayName or (model and model.Name) or "UNKNOWN"

			infoName.Text = shown
			infoUser.Text = "NPC"
			avatar.Image = ""
			fallback.Visible = true
		end
	end

	function InfoCard.preview()
		shownRoot = nil
		showPlayer(LP)
		card.Visible = true
		applyElement("targetInfo")
	end

	function InfoCard.hide()
		shownRoot = nil

		if not editMode then
			card.Visible = false
		end
	end

	function InfoCard.update(root, aimPos)
		if not root or not root.Parent then
			InfoCard.hide()
			return
		end

		local sp = Camera:WorldToScreenPoint(aimPos)

		if sp.Z <= 0 then
			card.Visible = false
			return
		end

		if root ~= shownRoot then
			populate(root)
		end

		local vp = getViewport()
		local L = layout.targetInfo
		local sc = scaleOf("targetInfo")

		local dx = ((L and L.x or HOME_X) - HOME_X) * vp.X
		local dy = ((L and L.y or HOME_Y) - HOME_Y) * vp.Y

		local halfW = INFO_W * sc / 2
		local minY = INFO_H * sc

		local x = math.clamp(sp.X + dx, halfW, math.max(vp.X - halfW, halfW))
		local y = math.clamp(sp.Y - GAP + dy, minY, math.max(vp.Y, minY))

		card.Position = UDim2.fromOffset(x, y)
		card.Visible = true
	end
end

local function previewHud()
	telemetry.Text = "GS   0000 st/s\nMAX  0000 st\nAIR  000.0 s\nTHR  000%\nPIT  +00°\nTGT  --- st"
	headingReadout.Text = "HDG 000°"
	speedReadoutText.Text = tostring(K.SPEED)
	updateHeadingTape(0)
	updateSpeedTape(K.SPEED)
	updateAltTape(0)
	InfoCard.preview()
end

editLayer = Instance.new("Frame")
editLayer.Name = "Editor"
editLayer.Size = UDim2.fromScale(1, 1)
editLayer.BackgroundTransparency = 1
editLayer.Active = false
editLayer.ZIndex = 300
editLayer.Parent = gui

local editPanel = Instance.new("Frame")
editPanel.Name = "EditPanel"
editPanel.Size = UDim2.fromOffset(340, 142)
editPanel.AnchorPoint = Vector2.new(0.5, 1)
editPanel.Position = UDim2.new(0.5, 0, 1, -12)
editPanel.BackgroundColor3 = Color3.fromRGB(60, 62, 72)
editPanel.BorderSizePixel = 0
editPanel.Visible = false
editPanel.ZIndex = 2
editPanel.Active = true
editPanel.Parent = editLayer

addCorner(editPanel, 16)
addStroke(editPanel, SHOP.Dark, 3, 0)

do
	local editTitle = Instance.new("TextLabel")
	editTitle.Size = UDim2.fromOffset(316, 16)
	editTitle.Position = UDim2.fromOffset(12, 8)
	editTitle.BackgroundTransparency = 1
	FX.tr(editTitle, "ed_title")
	editTitle.TextColor3 = THEME.Accent
	editTitle.TextSize = 13
	editTitle.Font = Enum.Font.GothamBlack
	editTitle.TextXAlignment = Enum.TextXAlignment.Left
	editTitle.Parent = editPanel

	local editHint = Instance.new("TextLabel")
	editHint.Size = UDim2.fromOffset(316, 14)
	editHint.Position = UDim2.fromOffset(12, 24)
	editHint.BackgroundTransparency = 1
	FX.tr(editHint, "ed_hint")
	editHint.TextColor3 = THEME.Muted
	editHint.TextSize = 10
	editHint.Font = Enum.Font.GothamMedium
	editHint.TextXAlignment = Enum.TextXAlignment.Left
	editHint.Parent = editPanel
end

local nameLabel = hudText(editPanel, "", UDim2.fromOffset(316, 16), UDim2.fromOffset(12, 42))
nameLabel.TextSize = 13
nameLabel.TextColor3 = THEME.Cyan
nameLabel.Font = Enum.Font.GothamBold

local sizeLabel = hudText(editPanel, "", UDim2.fromOffset(150, 34), UDim2.fromOffset(60, 62), Enum.TextXAlignment.Center)
sizeLabel.TextSize = 14
sizeLabel.Font = Enum.Font.GothamBold

function updateEditorPanel()
	if not selectedId or not ELEMENTS[selectedId] then
		nameLabel.Text = FX.L("ed_select")
		sizeLabel.Text = "--"
		return
	end

	nameLabel.Text = FX.elName(selectedId, ELEMENTS[selectedId].name)
	sizeLabel.Text = string.format(FX.L("ed_size") .. " %d%%", math.floor(scaleOf(selectedId) * 100 + 0.5))
end

local function resizeSelected(delta)
	if not selectedId then
		return
	end

	local L = ensureLayout(selectedId)
	local newScale = scaleOf(selectedId) + delta

	L.s = math.clamp(math.floor(newScale / K.SCALE_STEP + 0.5) * K.SCALE_STEP, K.MIN_LAYOUT_SCALE, K.MAX_LAYOUT_SCALE)

	applyElement(selectedId)
	updateEditorPanel()
	scheduleSave()
end

local function resetSelected()
	if not selectedId then
		return
	end

	layout[selectedId] = nil
	applyElement(selectedId)
	updateEditorPanel()
	scheduleSave()
end

local function resetAll()
	for id in pairs(layout) do
		layout[id] = nil
	end

	applyAll()
	scheduleSave()
end

makeHudButton(editPanel, "−", UDim2.fromOffset(44, 34), UDim2.fromOffset(12, 62), Vector2.new(0, 0), THEME.Cyan, function()
	resizeSelected(-K.SCALE_STEP)
end)

makeHudButton(editPanel, "+", UDim2.fromOffset(44, 34), UDim2.fromOffset(214, 62), Vector2.new(0, 0), THEME.Cyan, function()
	resizeSelected(K.SCALE_STEP)
end)

makeHudButton(editPanel, { key = "ed_reset" }, UDim2.fromOffset(62, 34), UDim2.fromOffset(266, 62), Vector2.new(0, 0), THEME.Warn, function()
	resetSelected()
end)

makeHudButton(editPanel, { key = "ed_resetall" }, UDim2.fromOffset(154, 28), UDim2.fromOffset(12, 104), Vector2.new(0, 0), THEME.Danger, function()
	resetAll()
end)

makeHudButton(editPanel, { key = "ed_done" }, UDim2.fromOffset(154, 28), UDim2.fromOffset(174, 104), Vector2.new(0, 0), THEME.Accent, function()
	setEditMode(false)
end)

do
	local DARK = SHOP.Dark
	local PW, PH = 204, 208

	local picker = Instance.new("CanvasGroup")
	picker.Name = "BombPicker"
	picker.Size = UDim2.fromOffset(PW, PH)
	picker.AnchorPoint = Vector2.new(1, 0)
	picker.Position = UDim2.new(1, -15, 0, 85)
	picker.BackgroundColor3 = Color3.fromRGB(60, 62, 72)
	picker.BorderSizePixel = 0
	picker.Active = true
	picker.Visible = false
	picker.ZIndex = 210
	picker.Parent = gui

	addCorner(picker, 14)
	addStroke(picker, DARK, 3, 0)

	local header = Instance.new("Frame")
	header.Name = "PickerHeader"
	header.Size = UDim2.new(1, 0, 0, 34)
	header.BackgroundColor3 = Color3.new(1, 1, 1)
	header.BorderSizePixel = 0
	header.Active = true
	header.Parent = picker

	local hg = Instance.new("UIGradient")
	hg.Color = ColorSequence.new(Color3.fromRGB(255, 228, 118), Color3.fromRGB(245, 178, 46))
	hg.Rotation = 90
	hg.Parent = header

	local shine = Instance.new("Frame")
	shine.Size = UDim2.new(1, 0, 0.5, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.8
	shine.BorderSizePixel = 0
	shine.Parent = header

	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, 0, 0, 3)
	line.Position = UDim2.new(0, 0, 1, -3)
	line.BackgroundColor3 = DARK
	line.BorderSizePixel = 0
	line.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -46, 1, -3)
	title.Position = UDim2.fromOffset(10, 0)
	title.BackgroundTransparency = 1
	FX.tr(title, "pk_title")
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 16
	title.Font = Enum.Font.FredokaOne
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local titleStroke = addStroke(title, DARK, 2, 0)
	titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(24, 24)
	closeBtn.Position = UDim2.new(1, -30, 0, 4)
	closeBtn.BackgroundColor3 = SHOP.Blue
	closeBtn.BorderSizePixel = 0
	closeBtn.AutoButtonColor = false
	closeBtn.Text = "−"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextSize = 15
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.Parent = header

	addCorner(closeBtn, 7)
	addStroke(closeBtn, DARK, 2, 0)

	local cg = Instance.new("UIGradient")
	cg.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200))
	cg.Rotation = 90
	cg.Parent = closeBtn

	local cts = addStroke(closeBtn, DARK, 1.5, 0)
	cts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

	closeBtn.MouseEnter:Connect(function()
		playUI("Hover")
		tween(closeBtn, 0.15, { BackgroundColor3 = SHOP.Blue:Lerp(Color3.new(1, 1, 1), 0.2) })
	end)

	closeBtn.MouseLeave:Connect(function()
		tween(closeBtn, 0.2, { BackgroundColor3 = SHOP.Blue })
	end)

	header.InputBegan:Connect(function(input)
		if isPress(input) then
			beginDrag("picker", input)
		end
	end)

	local inset = Instance.new("Frame")
	inset.Position = UDim2.fromOffset(8, 42)
	inset.Size = UDim2.new(1, -16, 1, -50)
	inset.BackgroundColor3 = Color3.fromRGB(38, 40, 48)
	inset.BorderSizePixel = 0
	inset.Parent = picker

	addCorner(inset, 10)
	addStroke(inset, Color3.fromRGB(20, 21, 27), 2, 0)

	closeBtn.Activated:Connect(function()
		playUI("Click")

		FX.pickerFolded = not FX.pickerFolded

		inset.Visible = not FX.pickerFolded
		closeBtn.Text = FX.pickerFolded and "+" or "−"
		FX.pickerApplySize()
	end)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = inset

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = inset

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, 0, 0, 26)
	hint.BackgroundTransparency = 1
	FX.tr(hint, nil, function()
		return FX.L(FX.pickerKind == "swarm" and "pk_hint2" or "pk_hint")
	end)
	hint.TextColor3 = THEME.Muted
	hint.TextSize = 10
	hint.TextWrapped = true
	hint.Font = Enum.Font.GothamBold
	hint.LayoutOrder = 1
	hint.Parent = inset

	local function fit(b, maxSize)
		b.TextScaled = true

		local lim = Instance.new("UITextSizeConstraint")
		lim.MaxTextSize = maxSize
		lim.MinTextSize = 7
		lim.Parent = b
	end

	local function newPick(order)
		local b = createButton("", inset)

		b.Size = UDim2.new(1, 0, 0, 36)
		b.LayoutOrder = order
		fit(b, 14)

		return b
	end

	local pickA = newPick(2)
	local pickB = newPick(3)
	local pickC = newPick(4)

	local function guarded(fn)
		return function()
			if droneActive or editMode then
				return
			end

			fn()
		end
	end

	pickA.Activated:Connect(function()
		if FX.pickerKind == "swarm" then
			guarded(function()
				SW.add()
			end)()
		else
			FX.selectBomb()
		end
	end)

	pickB.Activated:Connect(function()
		if FX.pickerKind == "swarm" then
			guarded(function()
				SW.clear()
			end)()
		else
			FX.toggleDrone()
		end
	end)

	pickC.Activated:Connect(guarded(function()
		if FX.tab == 2 then
			SW.launch()
		elseif FX.tab == 5 then
			SW.launchScatter()
		else
			SW.attackOrbit()
		end
	end))

	local menuBtn = createButton({ key = "pk_menu" }, inset)
	menuBtn.Size = UDim2.new(1, 0, 0, 30)
	menuBtn.LayoutOrder = 5
	fit(menuBtn, 14)

	menuBtn.Activated:Connect(function()
		if editMode then
			return
		end

		setMenuOpen(not menuVisible)
	end)

	register("picker", "BOMB PICKER", picker)

	local cross = Instance.new("Frame")
	cross.Name = "PickerAim"
	cross.Size = UDim2.fromOffset(18, 18)
	cross.AnchorPoint = Vector2.new(0.5, 0.5)
	cross.BackgroundTransparency = 1
	cross.Visible = false
	cross.ZIndex = 150
	cross.Parent = gui

	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundTransparency = 1
	ring.Parent = cross

	addCorner(ring, 9)
	addStroke(ring, SHOP.Green, 2, 0)

	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(4, 4)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.BackgroundColor3 = Color3.new(1, 1, 1)
	dot.BorderSizePixel = 0
	dot.Parent = cross

	addCorner(dot, 2)
	addStroke(dot, DARK, 1, 0)

	local GuiService = game:GetService("GuiService")

	local H_DRONE, H_SWARM = 214, 256

	function FX.pickerApplySize()
		local full = (FX.pickerKind == "swarm") and H_SWARM or H_DRONE

		inset.Visible = not FX.pickerFolded
		picker.Size = UDim2.fromOffset(PW, FX.pickerFolded and 34 or full)
	end

	local function follow(dst, src, text)
		if not src then
			return
		end

		local sd, ss = buttonStyles[dst], buttonStyles[src]

		if text ~= false and dst.Text ~= src.Text then
			dst.Text = src.Text
		end

		if sd and ss and sd.Base ~= ss.Base then
			sd.Base = ss.Base

			tween(dst, 0.2, { BackgroundColor3 = ss.Base })
			tween(sd.Stroke, 0.2, { Color = shopEdge(ss.Base) })
			tween(sd.TextStroke, 0.2, { Color = shopEdge(ss.Base) })
		end
	end

	-- Panel besar hanya untuk tab DRONE dan DRONE V2.
	FX.pickerKind = "drone"
	hint.Text = FX.L("pk_hint")
	pickC.Visible = false
	FX.pickerApplySize()

	FX.conn(RunService.RenderStepped, function()
		local tab = FX.tab

		local kind = nil

		if FX.page == "menu" then
			if tab == 1 or tab == 10 then
				kind = "drone"
			elseif tab >= 2 and tab <= 5 then
				kind = "swarm"
			end
		end

		local want = kind ~= nil and not droneActive
		local showPanel = want and kind == "drone"

		picker.Visible = showPanel or editMode
		cross.Visible = want and not editMode and (kind == "swarm" or not FX.pickerFolded)

		if showPanel then
			follow(pickA, bombButton)
			follow(pickB, droneButton)
		end

		if want then
			local vp = Camera.ViewportSize
			local gi = GuiService:GetGuiInset()

			cross.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2 - gi.Y)
		end
	end)
end

for id, e in pairs(ELEMENTS) do

	if id == "menu" then
		continue
	end

	local h = Instance.new("TextButton")
	h.Name = "Handle_" .. id
	h.Size = UDim2.fromOffset(40, 40)
	h.BackgroundColor3 = THEME.Cyan
	h.BackgroundTransparency = 0.88
	h.BorderSizePixel = 0
	h.AutoButtonColor = false
	h.Text = ""
	h.Visible = false
	h.Parent = editLayer

	addStroke(h, THEME.Cyan, 1, 0)

	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.new(1, 0, 0, 14)
	tag.Position = UDim2.fromOffset(0, -14)
	tag.BackgroundColor3 = THEME.Cyan
	tag.BackgroundTransparency = 0.1
	tag.BorderSizePixel = 0
	FX.tr(tag, nil, function()
		return " " .. FX.elName(id, e.name)
	end)
	tag.TextColor3 = Color3.new(0, 0, 0)
	tag.TextSize = 9
	tag.Font = Enum.Font.GothamBold
	tag.TextXAlignment = Enum.TextXAlignment.Left
	tag.Parent = h

	h.InputBegan:Connect(function(input)
		if editMode and isPress(input) then
			selectElement(id)
			beginDrag(id, input)
		end
	end)

	handles[id] = h
end

function selectElement(id)
	selectedId = id

	for hid, h in pairs(handles) do
		local on = hid == id
		local st = h:FindFirstChildOfClass("UIStroke")

		st.Color = on and THEME.Accent or THEME.Cyan
		st.Thickness = on and 2 or 1
		h.BackgroundTransparency = on and 0.7 or 0.88
	end

	updateEditorPanel()
end

FX.conn(RunService.RenderStepped, function()
	if not editMode then
		return
	end

	local origin = editLayer.AbsolutePosition

	for id, e in pairs(ELEMENTS) do
		local h = handles[id]

		if not h then
			continue
		end

		local ap = e.frame.AbsolutePosition
		local as = e.frame.AbsoluteSize

		h.Position = UDim2.fromOffset(ap.X - origin.X, ap.Y - origin.Y)
		h.Size = UDim2.fromOffset(math.max(as.X, 12), math.max(as.Y, 12))
	end
end)

function setEditMode(on)
	if on and droneActive then
		return
	end

	editMode = on
	editPanel.Visible = on

	for _, h in pairs(handles) do
		h.Visible = on
	end

	if on then

		FX.menuWasOpen = menuVisible
		setMenuOpen(false, true)
		hud.Visible = true
		previewHud()
		selectElement(selectedId or "telemetry")
	else
		selectedId = nil
		hud.Visible = false
		InfoCard.hide()
		scheduleSave()

		if FX.menuWasOpen then
			FX.menuWasOpen = false
			setMenuOpen(true, true)
		end
	end
end

local function updateSpeedUI()
	speedLabel.Text = FX.L("speed") .. " " .. K.SPEED
	speedReadoutText.Text = tostring(K.SPEED)

	tween(menuSpeedFill, 0.25, {
		Size = UDim2.new(math.clamp(K.SPEED / K.MAX_SPEED, 0, 1), 0, 1, 0),
	})
end

function changeSpeed(delta)
	K.SPEED = math.clamp(K.SPEED + delta, K.MIN_SPEED, K.MAX_SPEED)
	updateSpeedUI()
	scheduleSave()
end

speedDown.Activated:Connect(function()
	changeSpeed(-K.SPEED_STEP)
end)

speedUp.Activated:Connect(function()
	changeSpeed(K.SPEED_STEP)
end)

local function refreshDroneButton()
	if droneActive then
		droneButton.Text = FX.L("btn_drone_on")
		applyButtonStyle(droneButton, THEME.OnBase, THEME.Accent, 0.3)
	else
		droneButton.Text = FX.L("btn_drone_off")
		applyButtonStyle(droneButton, THEME.Panel, THEME.Cyan, 0.75)
	end
end

local function resetBombButton()

	if FX.V2.on and FX.V2.paintBomb then
		FX.V2.paintBomb()
		return
	end

	bombButton.Text = FX.L("btn_bomb")
	applyButtonStyle(bombButton, THEME.Panel, THEME.Cyan, 0.75)
end

function FX.onLang()
	if FX.paintLang then
		FX.paintLang()
	end

	for _, refresh in pairs(FX.togglers) do
		refresh()
	end

	FX.boostText = ""
	setStatus(FX.statusActive)
	refreshDroneButton()
	bombButton.Text = FX.L("btn_bomb")

	if FX.V2.on and FX.V2.paintBomb then
		FX.V2.paintBomb()
	end

	updateSpeedUI()
	refreshLockUI()
	updateEditorPanel()

	if SW.refresh then
		SW.refresh()
	end

	if FX.rangeLabel then
		FX.rangeLabel.Text = string.format(FX.L("rng") .. " %d ST", Cfg.radarRange)
	end
end

local function updateDroneUI()
	local active = droneActive
		and bombFlying
		and selectedBomb ~= nil
		and selectedBomb.Parent ~= nil

	hud.Visible = active

	if active then
		if not droneSound.IsPlaying then
			droneSound:Play()
		end
	elseif droneSound.IsPlaying then
		droneSound:Stop()
	end
end

local function getBombTarget()
	local origin = Camera.CFrame.Position
	local direction = Camera.CFrame.LookVector * 1500

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local ignore = { LP.Character }

	for _, b in ipairs(SW.bombs) do
		table.insert(ignore, b.part)
	end

	for _, p in ipairs(FX.V2.satParts()) do
		table.insert(ignore, p)
	end

	params.FilterDescendantsInstances = ignore

	local result = workspace:Raycast(origin, direction, params)

	if not result then
		return nil
	end

	local obj = result.Instance

	for _ = 1, 8 do
		if not obj then
			break
		end

		local name = string.lower(obj.Name)

		if string.find(name, "bomb") or string.find(name, "bom") then
			if obj:IsA("BasePart") then
				return obj
			end

			local p = obj:FindFirstChildWhichIsA("BasePart", true)

			if p then
				return p
			end
		end

		obj = obj.Parent
	end

	return nil
end

local attachment
local velocity
local orientation

local function clearPhysics()
	if velocity then
		velocity:Destroy()
		velocity = nil
	end

	if orientation then
		orientation:Destroy()
		orientation = nil
	end

	if attachment then
		attachment:Destroy()
		attachment = nil
	end
end

local function setupPhysics(part)
	clearPhysics()

	attachment = Instance.new("Attachment")
	attachment.Parent = part

	velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = part

	orientation = Instance.new("AlignOrientation")
	orientation.Attachment0 = attachment
	orientation.MaxTorque = math.huge
	orientation.Responsiveness = 200
	orientation.Parent = part
end

local function readCameraAngles()
	local look = Camera.CFrame.LookVector

	yaw = math.atan2(-look.X, -look.Z)
	pitch = math.asin(math.clamp(look.Y, -1, 1))

	targetYaw = yaw
	targetPitch = pitch
end

local function getLookVector()
	local cp = math.cos(pitch)
	return Vector3.new(-math.sin(yaw) * cp, math.sin(pitch), -math.cos(yaw) * cp)
end

function FX.askFriend(plr)
	if Cfg.friendAsked[plr.UserId] then
		return
	end

	Cfg.friendAsked[plr.UserId] = true

	task.spawn(function()
		local ok, res = pcall(function()
			return LP:IsFriendsWith(plr.UserId)
		end)

		Cfg.friends[plr.UserId] = ok and res == true
	end)
end

function FX.allowed(plr)
	if Cfg.friendCheck then
		FX.askFriend(plr)

		if Cfg.friends[plr.UserId] ~= false then
			return false
		end
	end

	return true
end

local function scanContacts()
	table.clear(contacts)

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			local model = plr.Character
			local hum = model and model:FindFirstChildOfClass("Humanoid")

			if hum and hum.Health > 0 then
				local root = model:FindFirstChild("HumanoidRootPart")
					or hum.RootPart
					or model:FindFirstChild("Torso")
					or model:FindFirstChild("UpperTorso")
					or model:FindFirstChild("Head")

				if root and root:IsA("BasePart") and root.Parent then
					table.insert(contacts, {
						root = root,
						hum = hum,
						player = plr,
						allowed = FX.allowed(plr),
					})
				end
			end
		end
	end
end

local function getAimPoint(root)
	local model = root.Parent
	local head = model and model:FindFirstChild("Head")

	if head then
		return head.Position
	end

	return root.Position + Vector3.new(0, 1.5, 0)
end

function FX.candidates()
	local list = {}

	if not selectedBomb then
		return list
	end

	local bombPos = selectedBomb.Position

	for _, c in ipairs(contacts) do
		if c.allowed and c.root.Parent and c.hum.Health > 0 then
			local aim = getAimPoint(c.root)
			local dist = (aim - bombPos).Magnitude

			if dist > 1 and Camera:WorldToViewportPoint(aim).Z > 0 then
				table.insert(list, { root = c.root, dist = dist })
			end
		end
	end

	table.sort(list, function(a, b)
		return a.dist < b.dist
	end)

	return list
end

local function findLockTarget()
	local list = FX.candidates()

	return list[1] and list[1].root or nil
end

function FX.cycleTarget()
	if not droneActive or not selectedBomb then
		return
	end

	if not lockEnabled then
		setLock(true)
		return
	end

	scanContacts()

	local list = FX.candidates()

	if #list < 2 then
		showMessage(FX.L("m_noother"), THEME.Warn)
		playUI("Error")
		return
	end

	local idx = 0

	for i, e in ipairs(list) do
		if e.root == lockRoot then
			idx = i
			break
		end
	end

	lockRoot = list[idx % #list + 1].root

	showMessage(FX.L("m_switched"), THEME.Danger)
	playUI("On")
end

function FX.doBoost()
	if not droneActive or not bombFlying or not selectedBomb or editMode then
		return
	end

	local now = os.clock()

	if now < FX.boostUntil then
		return
	end

	if now < FX.boostReadyAt then
		showMessage(FX.L("m_boost_cd"), THEME.Warn)
		playUI("Error")
		return
	end

	FX.boostUntil = now + FX.boostTime
	FX.boostReadyAt = FX.boostUntil + FX.boostCooldown

	showMessage(FX.L("m_boost"), THEME.Warn)
	playUI("On")
end

function setLock(on, reason)
	if on then
		if not droneActive or not selectedBomb then
			return
		end

		scanContacts()
		local t = findLockTarget()

		if not t then
			showMessage(FX.L("m_notarget"), THEME.Danger)
			playUI("Error")
			return
		end

		lockRoot = t
		lockEnabled = true

		showMessage(FX.L("m_locked"), THEME.Danger)
		playUI("On")
	else
		local wasLocked = lockEnabled

		lockEnabled = false
		lockRoot = nil

		if reason then
			showMessage(reason, THEME.Warn)
		end

		if wasLocked then
			playUI("Off")
		end
	end

	refreshLockUI()
end

local function updateReticle(bombPos)
	lockGui.Enabled = droneActive and bombFlying

	if lockEnabled and lockRoot and lockRoot.Parent then
		local aimPos = getAimPoint(lockRoot)
		local sp = Camera:WorldToViewportPoint(aimPos)

		setReticleColor(THEME.Danger)

		if sp.Z > 0 then
			reticle.Position = UDim2.fromOffset(sp.X, sp.Y)
			reticle.Size = UDim2.fromOffset(64, 64)

			local dist = (aimPos - bombPos).Magnitude
			lockLabel.Text = string.format(FX.L("lock_lbl") .. "  %04d ST", math.floor(dist))

			InfoCard.update(lockRoot, aimPos)
		else
			reticle.Position = UDim2.fromScale(0.5, 0.5)
			reticle.Size = UDim2.fromOffset(RET_SIZE, RET_SIZE)
			lockLabel.Text = FX.L("tgt_behind")
			InfoCard.hide()
		end
	else
		setReticleColor(HUD_GREEN)
		reticle.Position = UDim2.fromScale(0.5, 0.5)
		reticle.Size = UDim2.fromOffset(RET_SIZE, RET_SIZE)
		lockLabel.Text = ""
		InfoCard.hide()
	end
end

local function updateRadar(bombPos, fwdFlat, rightVec)
	local r = K.RADAR_SIZE / 2 - 8
	local used = 0
	local range = Cfg.radarRange

	for _, c in ipairs(contacts) do
		if used >= #radarDots then
			break
		end

		if c.root.Parent then
			local d = c.root.Position - bombPos
			local dx = d:Dot(rightVec)
			local dz = d:Dot(fwdFlat)

			if Vector2.new(dx, dz).Magnitude <= range then
				used += 1

				local dot = radarDots[used]
				local isLocked = lockEnabled and c.root == lockRoot

				dot.Position = UDim2.fromOffset(
					K.RADAR_SIZE / 2 + dx / range * r,
					K.RADAR_SIZE / 2 - dz / range * r
				)

				dot.Size = isLocked and UDim2.fromOffset(11, 11) or UDim2.fromOffset(7, 7)
				dot.BackgroundColor3 = isLocked and THEME.Danger
					or (c.allowed and THEME.Warn or THEME.Accent)

				radarBlips[used] = {
					bearing = math.deg(math.atan2(dx, dz)) % 360,
					locked = isLocked,
				}
			end
		end
	end

	radarBlipCount = used

	for i = used + 1, #radarDots do
		radarDots[i].Visible = false
	end
end

function FX.noSignal()
	if not Cfg.noSignal or FX.nsBusy then
		return
	end

	FX.nsBusy = true

	local DURATION = 1.0
	local vp = Camera.ViewportSize
	local rng = Random.new()

	local sg = Instance.new("ScreenGui")
	sg.Name = "DroneNoSignal"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 100
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = PlayerGui

	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.new(1, 1, 1)
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.Parent = sg

	local bars = {}

	for i = 1, 64 do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundTransparency = 1
		f.ZIndex = 2
		f.Parent = root
		bars[i] = f
	end

	for i = 0, 47 do
		local l = Instance.new("Frame")
		l.Size = UDim2.new(1, 0, 0, 2)
		l.Position = UDim2.fromScale(0, i / 48)
		l.BackgroundColor3 = Color3.new(0, 0, 0)
		l.BackgroundTransparency = 0.8
		l.BorderSizePixel = 0
		l.ZIndex = 3
		l.Parent = root
	end

	local textSize = math.clamp(math.floor(vp.Y * 0.1), 30, 72)

	local function makeTitle(color, z)
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, 0, 0, textSize + 10)
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Position = UDim2.new(0.5, 0, 0.5, -10)
		t.BackgroundTransparency = 1
		t.Text = FX.L("ns_title")
		t.Font = Enum.Font.GothamBlack
		t.TextSize = textSize
		t.TextColor3 = color
		t.TextTransparency = 1
		t.ZIndex = z
		t.Parent = root
		return t
	end

	local red = makeTitle(Color3.fromRGB(255, 40, 60), 5)
	local cyan = makeTitle(Color3.fromRGB(0, 230, 255), 6)
	local main = makeTitle(Color3.fromRGB(240, 245, 245), 7)

	local sub = hudText(root, FX.L("ns_sub"), UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0.5, math.floor(textSize * 0.6)), Enum.TextXAlignment.Center)
	sub.TextSize = math.clamp(math.floor(vp.Y * 0.03), 12, 20)
	sub.TextColor3 = THEME.Danger
	sub.TextStrokeTransparency = 1
	sub.ZIndex = 8

	local cornerA = hudText(root, FX.L("ns_a"), UDim2.fromOffset(260, 18), UDim2.fromOffset(16, 14))
	cornerA.TextColor3 = THEME.Danger
	cornerA.TextStrokeTransparency = 1
	cornerA.ZIndex = 8

	local cornerB = hudText(root, FX.L("ns_b"), UDim2.fromOffset(260, 18), UDim2.new(0, 16, 1, -30))
	cornerB.TextColor3 = Color3.fromRGB(235, 240, 240)
	cornerB.TextStrokeTransparency = 1
	cornerB.ZIndex = 8

	local sounds = {}

	local function mk(id, vol, speed, looped)
		local ok, s = pcall(function()
			local snd = Instance.new("Sound")
			snd.Name = "DroneUI_NoSignal"
			snd.SoundId = id
			snd.Volume = vol
			snd.PlaybackSpeed = speed
			snd.Looped = looped or false
			snd.Parent = SoundService
			return snd
		end)

		if ok and s then
			table.insert(sounds, s)
			return s
		end

		return nil
	end

	local buzz = mk("rbxasset://sounds/electronicpingshort.wav", 0.5, 0.5, true)

	if buzz then
		local dist = Instance.new("DistortionSoundEffect")
		dist.Level = 0.85
		dist.Parent = buzz
	end

	local thud = mk("rbxasset://sounds/electronicpingshort.wav", 0.9, 0.25, false)
	local glitchTick = mk("rbxasset://sounds/clickfast.wav", 0.5, 1, false)
	local custom = FX.STATIC_SOUND_ID ~= "" and mk(FX.STATIC_SOUND_ID, 0.7, 1, false) or nil

	if buzz then buzz:Play() end
	if thud then thud:Play() end
	if custom then custom:Play() end

	local t0 = os.clock()
	local lastBuzz = 0
	local conn

	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0

		if t >= DURATION then
			conn:Disconnect()
			sg:Destroy()

			for _, s in ipairs(sounds) do
				s:Stop()
				s:Destroy()
			end

			FX.nsBusy = false
			return
		end

		local fo = math.clamp((t - 0.72) / 0.28, 0, 1)
		local alpha = fo * fo * (3 - 2 * fo)

		local fl = math.clamp(t / 0.1, 0, 1)
		root.BackgroundColor3 = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(10, 12, 14), fl)
		root.BackgroundTransparency = alpha

		local burst = t < 0.25 or math.noise(t * 14, 0.37, 0.91) > 0.28
		local intensity = t < 0.1 and 1 or (burst and 0.8 or 0.45)

		for _, f in ipairs(bars) do
			if rng:NextNumber() < intensity then
				local h = rng:NextInteger(1, 4)

				if rng:NextNumber() < 0.08 then
					h = rng:NextInteger(8, 38)
				end

				local w = rng:NextNumber(0.15, 1)
				local g = rng:NextInteger(40, 255)
				local tint = rng:NextNumber()

				f.Size = UDim2.new(w, 0, 0, h)
				f.Position = UDim2.new(rng:NextNumber(0, 1 - w), 0, rng:NextNumber(), 0)

				if tint < 0.1 then
					f.BackgroundColor3 = Color3.fromRGB(255, 40, 60)
				elseif tint < 0.2 then
					f.BackgroundColor3 = Color3.fromRGB(0, 230, 255)
				else
					f.BackgroundColor3 = Color3.fromRGB(g, g, g)
				end

				f.BackgroundTransparency = math.clamp(1 - (1 - alpha) * rng:NextNumber(0.25, 0.8), 0, 1)
			else
				f.BackgroundTransparency = 1
			end
		end

		local tIn = math.clamp((t - 0.06) / 0.12, 0, 1)
		local base = 1 - tIn * (1 - alpha)
		local flick = (burst and rng:NextNumber() < 0.35) and 0.55 or 0
		local tr = math.clamp(base + flick, 0, 1)
		local jitter = burst and rng:NextInteger(-6, 6) or 0
		local split = burst and rng:NextInteger(4, 12) or 2

		main.Position = UDim2.new(0.5, jitter, 0.5, -10)
		red.Position = UDim2.new(0.5, jitter - split, 0.5, -10)
		cyan.Position = UDim2.new(0.5, jitter + split, 0.5, -10)

		main.TextTransparency = tr
		red.TextTransparency = math.clamp(tr + 0.35, 0, 1)
		cyan.TextTransparency = math.clamp(tr + 0.35, 0, 1)

		local blink = (math.floor(t * 8) % 2 == 0) and tr or math.clamp(tr + 0.6, 0, 1)

		sub.TextTransparency = blink
		cornerA.TextTransparency = blink
		cornerB.TextTransparency = math.clamp(base + 0.2, 0, 1)

		if buzz then
			if t - lastBuzz > 0.045 then
				lastBuzz = t
				buzz.PlaybackSpeed = 0.35 + rng:NextNumber() * 1.5
			end

			buzz.Volume = 0.5 * (1 - alpha) * (burst and 1 or 0.55)
		end

		if glitchTick and burst and rng:NextNumber() < 0.25 then
			glitchTick.PlaybackSpeed = 0.6 + rng:NextNumber() * 2
			glitchTick:Play()
		end
	end)
end

local function triggerImpact(pos)

	FX.boom(pos)

	playUI("Error")
	FX.noSignal()
	stopDrone()
end

function FX.selectBomb()
	if droneActive or editMode then
		return
	end

	if FX.V2.on and FX.V2.select then
		FX.V2.select()
		return
	end

	local found = getBombTarget()

	if found then
		selectedBomb = found
		FX.skinApply(found, Cfg.skinId)

		bombButton.Text = FX.L("btn_bomb_ok")
		applyButtonStyle(bombButton, THEME.OnBase, THEME.Accent, 0.3)
		playUI("On")
	else
		selectedBomb = nil

		bombButton.Text = FX.L("btn_bomb_none")
		applyButtonStyle(bombButton, THEME.ErrorBase, THEME.Danger, 0.3)
		playUI("Error")
	end

	task.delay(1, function()
		if not droneActive then
			resetBombButton()
		end
	end)
end

bombButton.Activated:Connect(FX.selectBomb)

function stopDrone()
	local wasActive = droneActive

	if FX.V2.onStop then
		FX.V2.onStop(wasActive)
	end

	droneActive = false
	bombFlying = false

	forward = false
	backward = false
	left = false
	right = false

	clearPhysics()

	selectedBomb = nil
	cameraTouch = nil
	camReady = false

	setLock(false)

	FX.boostUntil = 0
	FX.boostReadyAt = 0
	FX.boostText = ""
	FX.hitT = nil
	FX.autoAtk = false
	FX.lastBombPos = nil

	if rightMouseDown then
		rightMouseDown = false
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end

	hud.Visible = false
	lockGui.Enabled = false
	InfoCard.hide()

	FX.speedK = 0
	FX.aim = nil
	FX.linesOn = false
	FX.fxGui.Enabled = false

	if wasActive then
		Camera.FieldOfView = FX.origFov
	end

	if droneSound.IsPlaying then
		droneSound:Stop()
	end

	Camera.CameraType = Enum.CameraType.Custom

	toggle.Visible = true

	refreshDroneButton()
	resetBombButton()
	setStatus(false)

	lastPosition = nil
	flightStart = 0
	maxAltitude = 0

	if wasActive then
		playUI("Off")
	end
end

function startDrone()
	if editMode then
		return
	end

	if not selectedBomb then
		selectedBomb = getBombTarget()

		if not selectedBomb then
			droneButton.Text = FX.L("btn_drone_nobomb")
			applyButtonStyle(droneButton, THEME.ErrorBase, THEME.Danger, 0.3)
			playUI("Error")

			task.delay(1, function()
				if not droneActive then
					refreshDroneButton()
				end
			end)

			return
		end
	end

	readCameraAngles()
	setupPhysics(selectedBomb)

	droneActive = true
	bombFlying = true
	camReady = false

	flightStart = os.clock()
	lastPosition = selectedBomb.Position
	maxAltitude = selectedBomb.Position.Y
	lastUpdate = os.clock()
	nextRadarScan = 0

	FX.origFov = Camera.FieldOfView
	FX.speedK = 0
	FX.aim = nil

	Camera.CameraType = Enum.CameraType.Scriptable

	setMenuOpen(false, true)
	toggle.Visible = false

	refreshDroneButton()
	setStatus(true)
	refreshLockUI()
	playUI("On")

	updateDroneUI()
	updateSpeedUI()
	showMessage(FX.L("m_link"), HUD_GREEN)

	if FX.V2.on and FX.V2.onStart then
		FX.V2.onStart()
	end
end

function FX.toggleDrone()
	if droneActive then
		stopDrone()
	else
		startDrone()
	end
end

droneButton.Activated:Connect(FX.toggleDrone)

local function bindDirection(button, name)
	button.InputBegan:Connect(function(input)
		if not droneActive then
			return
		end

		if isPress(input) then
			if name == "forward" then
				forward = true
			elseif name == "backward" then
				backward = true
			elseif name == "left" then
				left = true
			elseif name == "right" then
				right = true
			end
		end
	end)

	button.InputEnded:Connect(function(input)
		if isPress(input) then
			if name == "forward" then
				forward = false
			elseif name == "backward" then
				backward = false
			elseif name == "left" then
				left = false
			elseif name == "right" then
				right = false
			end
		end
	end)
end

bindDirection(upButton, "forward")
bindDirection(downButton, "backward")
bindDirection(leftButton, "left")
bindDirection(rightButton, "right")

local function isControlUI(object)
	return object == toggle
		or object == menu
		or object:IsDescendantOf(menu)
		or object:IsDescendantOf(toggle)
		or object:IsDescendantOf(controls)
		or object:IsDescendantOf(radar)
		or object:IsDescendantOf(bottomGroup)
		or object:IsDescendantOf(editLayer)
		or object:IsA("GuiButton")
end

local function applyLook(dx, dy, sensitivity)
	if lockEnabled then
		setLock(false, FX.L("m_lockbroken"))
	end

	sensitivity = sensitivity * (Cfg.sens / 100)

	targetYaw -= dx * sensitivity
	targetPitch = math.clamp(targetPitch - dy * sensitivity, -K.MAX_PITCH, K.MAX_PITCH)
end

FX.conn(UIS.InputBegan, function(input, gp)
	if not droneActive or editMode then
		return
	end

	if input.UserInputType == Enum.UserInputType.Touch then
		if gp or cameraTouch then
			return
		end

		local pos = input.Position
		local objects = gui:GetGuiObjectsAtPosition(pos.X, pos.Y)

		for _, object in ipairs(objects) do
			if isControlUI(object) then
				return
			end
		end

		cameraTouch = input

	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		if gp then
			return
		end

		rightMouseDown = true
		UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end
end)

FX.conn(UIS.InputChanged, function(input)
	if not droneActive or editMode then
		return
	end

	if input.UserInputType == Enum.UserInputType.Touch then
		if input == cameraTouch then
			applyLook(input.Delta.X, input.Delta.Y, K.CAMERA_SENSITIVITY)
		end

	elseif input.UserInputType == Enum.UserInputType.MouseMovement then
		if rightMouseDown then
			applyLook(input.Delta.X, input.Delta.Y, K.MOUSE_SENSITIVITY)
		end
	end
end)

FX.conn(UIS.InputEnded, function(input)
	if input == cameraTouch then
		cameraTouch = nil
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if rightMouseDown then
			rightMouseDown = false
			UIS.MouseBehavior = Enum.MouseBehavior.Default
		end
	end
end)

FX.conn(UIS.InputBegan, function(input, gp)
	if gp then
		return
	end

	local key = input.KeyCode

	if key == Enum.KeyCode.F then
		if droneActive then
			stopDrone()
		else
			startDrone()
		end

	elseif key == Enum.KeyCode.L then
		if droneActive then
			setLock(not lockEnabled)
		end

	elseif key == Enum.KeyCode.T then
		if droneActive then
			FX.cycleTarget()
		end

	elseif key == Enum.KeyCode.B then
		if droneActive then
			FX.doBoost()
		end

	elseif key == Enum.KeyCode.R then
		if droneActive then
			FX.cycleRadar()
		end

	elseif key == Enum.KeyCode.W then
		forward = true

	elseif key == Enum.KeyCode.S then
		backward = true

	elseif key == Enum.KeyCode.A then
		left = true

	elseif key == Enum.KeyCode.D then
		right = true

	elseif key == Enum.KeyCode.Q then
		changeSpeed(-K.SPEED_STEP)

	elseif key == Enum.KeyCode.E then
		changeSpeed(K.SPEED_STEP)
	end
end)

FX.conn(UIS.InputEnded, function(input)
	if input.KeyCode == Enum.KeyCode.W then
		forward = false
	elseif input.KeyCode == Enum.KeyCode.S then
		backward = false
	elseif input.KeyCode == Enum.KeyCode.A then
		left = false
	elseif input.KeyCode == Enum.KeyCode.D then
		right = false
	end
end)

FX.conn(RunService.RenderStepped, function()
	if not droneActive or not bombFlying or not selectedBomb then
		hud.Visible = editMode
		lockGui.Enabled = false
		return
	end

	if not selectedBomb.Parent then
		if FX.lastBombPos then

			FX.boom(FX.lastBombPos)

			playUI("Error")
		end

		FX.noSignal()
		stopDrone()
		return
	end

	FX.lastBombPos = selectedBomb.Position

	updateDroneUI()

	local now = os.clock()
	local dt = math.max(now - lastUpdate, 0.001)

	FX.updateBoostUI(now)

	if now >= nextRadarScan then
		nextRadarScan = now + K.RADAR_RATE
		scanContacts()
	end

	if lockEnabled then
		local model = lockRoot and lockRoot.Parent
		local hum = model and model:FindFirstChildOfClass("Humanoid")

		if not hum or hum.Health <= 0 then
			local t = findLockTarget()

			if t then
				lockRoot = t
			else
				setLock(false, FX.L("m_targetlost"))
			end
		end
	end

	if lockEnabled and lockRoot and lockRoot.Parent then
		local aimNow = getAimPoint(lockRoot)
		local distToAim = (aimNow - selectedBomb.Position).Magnitude
		local hitDist = K.IMPACT_DIST

		if now < FX.boostUntil then
			hitDist = math.max(K.IMPACT_DIST, K.SPEED * (Cfg.boost / 100) * math.min(dt, 0.05) * 1.25)
		end

		if distToAim < hitDist and not FX.hitT then
			local away = selectedBomb.Position - aimNow

			away = away.Magnitude > 0.1 and away.Unit or -getLookVector()

			local side = Vector3.new(-away.Z, 0, away.X)

			side = side.Magnitude > 0.1 and side.Unit or Vector3.new(1, 0, 0)

			FX.hitAway = (away + side * ((math.random() * 2 - 1) * 0.6) + Vector3.new(0, 0.35 + math.random() * 0.3, 0)).Unit
			FX.hitT = now

			showMessage(FX.L("sc_retry"), THEME.Warn)
		end
	end

	if lockEnabled and lockRoot then
		local toTarget = getAimPoint(lockRoot) - selectedBomb.Position

		if toTarget.Magnitude > 1 then
			local d = toTarget.Unit
			local desiredYaw = math.atan2(-d.X, -d.Z)
			local desiredPitch = math.asin(math.clamp(d.Y, -1, 1))

			targetYaw = yaw + wrapAngle(desiredYaw - yaw)
			targetPitch = math.clamp(desiredPitch, -K.MAX_PITCH, K.MAX_PITCH)
		end
	end

	local smooth = lockEnabled and K.LOCK_SMOOTHING or K.CAMERA_SMOOTHING
	local alpha = 1 - math.exp(-smooth * dt)

	yaw += wrapAngle(targetYaw - yaw) * alpha
	pitch += (targetPitch - pitch) * alpha

	local look = getLookVector()
	local cameraRight = CFrame.lookAt(Vector3.zero, look).RightVector
	local fwdFlat = Vector3.new(look.X, 0, look.Z)

	if fwdFlat.Magnitude < 0.001 then
		fwdFlat = Vector3.new(0, 0, -1)
	else
		fwdFlat = fwdFlat.Unit
	end

	local direction = Vector3.zero

	if forward then
		direction += look
	end

	if backward then
		direction -= look
	end

	if left then
		direction -= cameraRight
	end

	if right then
		direction += cameraRight
	end

	if direction.Magnitude > 0 then
		direction = direction.Unit
	end

	local boosting = now < FX.boostUntil

	if boosting and direction.Magnitude == 0 then
		direction = look
	end

	if FX.hitT or FX.autoAtk then
		if lockEnabled and lockRoot and lockRoot.Parent then
			local toAim = getAimPoint(lockRoot) - selectedBomb.Position
			local toDir = toAim.Magnitude > 0.05 and toAim.Unit or look

			if FX.hitT then
				local since = now - FX.hitT

				if since < FX.hitContact then
					direction = toDir * 0.6
				elseif since < FX.hitContact + FX.hitRetreat then
					direction = FX.hitAway * 0.45
				else
					FX.hitT = nil
					FX.autoAtk = true
					direction = toDir
				end
			else
				direction = toDir
			end
		else
			FX.hitT = nil
			FX.autoAtk = false
		end
	end

	local v2Launch = nil

	if FX.V2.on and FX.V2.launchVel then
		v2Launch = FX.V2.launchVel(now, selectedBomb)

		if v2Launch then
			direction = Vector3.new(0, 1, 0)
			boosting = false
		end
	end

	if velocity then
		velocity.VectorVelocity = v2Launch or (direction * K.SPEED * (boosting and (Cfg.boost / 100) or 1))
	end

	if orientation and direction.Magnitude > 0 then
		orientation.CFrame = v2Launch and FX.V2.upCFrame or CFrame.lookAt(Vector3.zero, direction)
	end

	local bombPos = selectedBomb.Position

	if not camReady then
		camFocus = bombPos
		camReady = true
	end

	camFocus = camFocus:Lerp(bombPos, 1 - math.exp(-K.CAMERA_FOLLOW * dt))

	local camPos = camFocus - look * Cfg.camDist + Vector3.new(0, K.CAMERA_HEIGHT, 0)

	local camLook = camPos + look

	if lockEnabled and lockRoot and lockRoot.Parent then
		local goal = getAimPoint(lockRoot)

		if not FX.aim then
			FX.aim = camPos + look * math.max((goal - camPos).Magnitude, 10)
		end

		FX.aim = FX.aim:Lerp(goal, 1 - math.exp(-10 * dt))
		camLook = FX.aim
	else
		FX.aim = nil
	end

	local camCF = CFrame.lookAt(camPos, camLook)

	local k = FX.speedK

	if k > 0.05 then
		local sx = math.noise(now * 22, 0.1, 0.5) * 0.28 * k
		local sy = math.noise(now * 25, 3.3, 1.7) * 0.28 * k
		local roll = math.noise(now * 18, 7.1, 2.9) * math.rad(1.4) * k

		camCF = camCF * CFrame.new(sx, sy, 0) * CFrame.Angles(0, 0, roll)
	end

	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.CFrame = camCF
	Camera.FieldOfView = Cfg.fov + k * 14

	local altitude = bombPos.Y
	maxAltitude = math.max(maxAltitude, altitude)

	local currentSpeed = 0

	if lastPosition then
		currentSpeed = (bombPos - lastPosition).Magnitude / dt
	end

	lastPosition = bombPos
	lastUpdate = now

	local targetK = Cfg.speedFx and math.clamp((currentSpeed - 150) / 700, 0, 1) or 0

	FX.speedK += (targetK - FX.speedK) * (1 - math.exp(-5 * dt))
	FX.updateLines(dt)

	local airTime = now - flightStart
	local heading = math.deg(math.atan2(-look.X, -look.Z))

	if heading < 0 then
		heading += 360
	end

	local pitchDegrees = math.deg(pitch)
	local throttle = math.clamp(direction.Magnitude, 0, 1) * 100

	ladder.Position = UDim2.new(0.5, 0, 0.5, pitchDegrees * PX_PER_DEG)
	updateReticle(bombPos)

	sweepAngle = (sweepAngle + dt * K.SWEEP_SPEED) % 360

	local sweepBearing = (sweepAngle + 90) % 360

	for i = 0, K.TRAIL_COUNT do
		sweepHolders[i].Rotation = sweepAngle - i * K.TRAIL_STEP
	end

	for i = 1, #radarDots do
		local dot = radarDots[i]

		if i <= radarBlipCount then
			local b = radarBlips[i]

			if b.locked then
				dot.Visible = true
				dot.BackgroundTransparency = 0
			else

				local behind = (sweepBearing - b.bearing) % 360
				local age = behind / K.SWEEP_SPEED

				if age < K.BLIP_FADE then
					dot.Visible = true
					dot.BackgroundTransparency = age / K.BLIP_FADE
				else
					dot.Visible = false
				end
			end
		else
			dot.Visible = false
		end
	end

	if now >= nextHudUpdate then
		nextHudUpdate = now + K.HUD_RATE

		updateHeadingTape(heading)
		updateSpeedTape(K.SPEED)
		updateAltTape(altitude)

		headingReadout.Text = string.format("HDG %03d°", math.floor(heading))

		local lockDist = nil

		if lockEnabled and lockRoot then
			lockDist = (getAimPoint(lockRoot) - bombPos).Magnitude
		end

		telemetry.Text = string.format(
			"GS   %04d st/s\nMAX  %04d st\nAIR  %05.1f s\nTHR  %03d%%\nPIT  %+03d°\nTGT  %s",
			math.floor(currentSpeed),
			math.floor(maxAltitude),
			airTime,
			math.floor(throttle),
			math.floor(pitchDegrees),
			lockDist and string.format("%04d st", math.floor(lockDist)) or "--- st"
		)

		updateRadar(bombPos, fwdFlat, cameraRight)
	end

	if messageLabel.Text ~= "" and now > messageUntil then
		messageLabel.Text = ""
	end
end)

xpcall(function()
	local env = (getgenv and getgenv()) or _G

	if type(env.__SwarmStrikeCleanup) == "function" then
		pcall(env.__SwarmStrikeCleanup)
	end

	local conns = {}

	local SCATTER_SPEED = 60
	local STAGGER = 0.12
	local ORBIT_APPROACH = 170
	local TURN_FAR = 7
	local TURN_NEAR = 16
	local NEAR_DIST = 80
	local HIT_GAP = 0.4
	local ATTACK_MAX = 5
	local SPIN_MULT = 4
	local WAVES = 3
	local WAVE_SPEED = 2.5
	local ORBIT_TGT_LIFT = 4
	local SPIN_RATE = 100
	local CONTACT_WAIT = 0.3
	local RETREAT_TIME = 0.4
	local RETREAT_MIN = 100
	local TN_BOTTOM = 0.35
	local TN_SQUEEZE = 0.35
	local ADD_SLOW_K = 0.2
	local ADD_SLOW_HOLD = 1.2
	local ADD_SLOW_RAMP = 1.6
	local JOIN_TIME = 2.2
	local JOIN_SPEED = 45

	local fxGui = Instance.new("ScreenGui")
	fxGui.Name = "DroneSwarmFx"
	fxGui.ResetOnSpawn = false
	fxGui.IgnoreGuiInset = true
	fxGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	fxGui.Parent = PlayerGui

	local box = Instance.new("Frame")
	box.Name = "SwarmTarget"
	box.Size = UDim2.fromOffset(64, 64)
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.BackgroundTransparency = 1
	box.Visible = false
	box.Parent = fxGui

	addStroke(box, THEME.Danger, 2, 0)

	local boxTag = hudText(box, "", UDim2.fromOffset(180, 14), UDim2.new(0.5, -90, 1, 4), Enum.TextXAlignment.Center)
	boxTag.TextColor3 = THEME.Danger
	boxTag.TextSize = 12

	function SW.say(text, color)
		SW.msgLabel.Text = text
		SW.msgLabel.TextColor3 = color or HUD_GREEN
		SW.msgUntil = os.clock() + 2.5
	end

	function SW.playerRoot()
		local ch = LP.Character

		return ch and ch:FindFirstChild("HumanoidRootPart") or nil
	end

	function SW.targetName()
		local model = SW.lockRoot and SW.lockRoot.Parent
		local plr = model and Players:GetPlayerFromCharacter(model)

		return plr and plr.Name or "?"
	end

	function SW.has(part)
		for _, b in ipairs(SW.bombs) do
			if b.part == part then
				return true
			end
		end

		return false
	end

	function SW.orbiters()
		local list = {}

		for _, b in ipairs(SW.bombs) do
			if b.phase == "orbit" then
				table.insert(list, b)
			end
		end

		return list
	end

	function SW.release(b)
		if b.av then
			b.av:Destroy()
			b.av = nil
		end

		if b.lv then
			b.lv:Destroy()
		end

		if b.ao then
			b.ao:Destroy()
		end

		if b.att then
			b.att:Destroy()
		end

		if b.part and b.part.Parent then
			pcall(function()
				b.part.CanCollide = b.cc
			end)
		end
	end

	function SW.startSpin(b)
		if b.av then
			b.av:Destroy()
			b.av = nil
		end

		if b.ao then
			b.ao.Enabled = true
		end
	end

	function SW.stopSpin(b)
		if b.av then
			b.av:Destroy()
			b.av = nil
		end

		if b.ao then
			b.ao.Enabled = true
		end
	end

	function SW.explode(pos)
		FX.boom(pos, true)
	end

	function SW.refreshLive()
		local n = #SW.bombs
		local waiting = #SW.orbiters()
		local flying = n - waiting

		local stateText = flying > 0 and FX.L("sw_launched") or FX.L("sw_orbit")

		SW.titleLabel.Text = FX.L("sw_title") .. " " .. n .. "/" .. Cfg.swarmMax .. " • " .. stateText
		SW.titleLabel.TextColor3 = Color3.new(1, 1, 1)

		local lockColor = SW.lockOn and THEME.Danger or HUD_GREEN

		SW.lockBtn.Text = SW.lockOn and FX.L("lock_on") or FX.L("lock_off")
		FX.hudPaint(SW.lockBtn, lockColor)

		local launchColor = waiting > 0 and THEME.Danger or THEME.Muted

		SW.launchBtn.Text = (SW.mode == "orbit" or SW.mode == "tornado") and FX.L("btn_orbit_attack") or FX.L("sw_launch")
		FX.hudPaint(SW.launchBtn, launchColor)

		if SW.lockOn and SW.lockRoot and SW.lockRoot.Parent then
			local me = SW.playerRoot()
			local d = me and (getAimPoint(SW.lockRoot) - me.Position).Magnitude or 0
			local info = string.format("%s  %d st", SW.targetName(), math.floor(d))

			SW.tgtLabel.Text = FX.L("sw_tgt") .. "  " .. info
			boxTag.Text = info
		elseif SW.mode == "scatter" then
			SW.tgtLabel.Text = FX.L("sw_tgt") .. "  " .. FX.L("sc_random") .. " x" .. #SW.bombs
		else
			SW.tgtLabel.Text = FX.L("sw_tgt") .. "  ---"
		end
	end

	function SW.refresh()
		SW.applyCollapse()

		local n = #SW.bombs
		local full = n >= Cfg.swarmMax

		for _, btn in ipairs({ SW.addButton, SW.addButton2, SW.addButton3, SW.addButton4 }) do
			btn.Text = FX.L("btn_swarm_add") .. " (" .. n .. "/" .. Cfg.swarmMax .. ")"

			applyButtonStyle(
				btn,
				full and THEME.OnBase or THEME.Panel,
				full and THEME.Accent or THEME.Cyan,
				full and 0.3 or 0.75
			)
		end

		if SW.paintList then
			SW.paintList()
		end

		SW.refreshLive()
	end

	local function flashAdd(text)
		for _, btn in ipairs({ SW.addButton, SW.addButton2, SW.addButton3, SW.addButton4 }) do
			btn.Text = text
			applyButtonStyle(btn, THEME.ErrorBase, THEME.Danger, 0.3)
		end

		task.delay(1, function()
			SW.refresh()
		end)
	end

	function SW.list()
		local list = {}
		local me = SW.playerRoot()
		local origin = me and me.Position or Camera.CFrame.Position

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LP then
				local model = plr.Character
				local hum = model and model:FindFirstChildOfClass("Humanoid")

				if hum and hum.Health > 0 and FX.allowed(plr) then
					local root = model:FindFirstChild("HumanoidRootPart")
						or hum.RootPart
						or model:FindFirstChild("Torso")
						or model:FindFirstChild("UpperTorso")
						or model:FindFirstChild("Head")

					if root and root:IsA("BasePart") and root.Parent then
						local aim = getAimPoint(root)

						table.insert(list, {
							root = root,
							aim = aim,
							dist = (aim - origin).Magnitude,
						})
					end
				end
			end
		end

		table.sort(list, function(a, b)
			return a.dist < b.dist
		end)

		return list
	end

	function SW.recall()
		local any = false

		for _, b in ipairs(SW.bombs) do
			if b.phase ~= "orbit" then
				SW.stopSpin(b)
				b.phase = "orbit"
				b.part.CanCollide = false
				any = true
			end
		end

		SW.spinUntil = nil

		return any
	end

	function SW.setLock(on, message)
		if on then

			if SW.mode == "scatter" then
				SW.say(FX.L("sc_nolock"), THEME.Warn)
				playUI("Error")
				return false
			end

			local list = SW.list()

			if #list == 0 then
				SW.say(FX.L("m_notarget"), THEME.Danger)
				playUI("Error")
				return false
			end

			local pick = list[1]

			for _, e in ipairs(list) do
				if Camera:WorldToViewportPoint(e.aim).Z > 0 then
					pick = e
					break
				end
			end

			SW.lockRoot = pick.root
			SW.lockOn = true

			SW.say(FX.L("m_locked"), THEME.Danger)
			playUI("On")
			SW.refresh()

			return true
		end

		local wasOn = SW.lockOn

		SW.lockOn = false
		SW.lockRoot = nil

		if SW.recall() then
			SW.say(FX.L("sw_recall"), THEME.Warn)
		elseif message then
			SW.say(message, THEME.Warn)
		end

		if wasOn then
			playUI("Off")
		end

		SW.refresh()

		return true
	end

	function SW.cycle()
		if droneActive or editMode or SW.mode == "scatter" then
			return
		end

		if not SW.lockOn then
			SW.setLock(true)
			return
		end

		local list = SW.list()

		if #list < 2 then
			SW.say(FX.L("m_noother"), THEME.Warn)
			playUI("Error")
			return
		end

		local idx = 0

		for i, e in ipairs(list) do
			if e.root == SW.lockRoot then
				idx = i
				break
			end
		end

		SW.lockRoot = list[idx % #list + 1].root

		SW.say(FX.L("m_switched"), THEME.Danger)
		playUI("On")
		SW.refresh()
	end

	function SW.add()
		if droneActive or editMode or FX.V2.on then
			return
		end

		SW.syncMode()

		if #SW.bombs >= Cfg.swarmMax then
			SW.say(FX.L("sw_full"), THEME.Warn)
			flashAdd(FX.L("sw_full"))
			playUI("Error")
			return
		end

		local part = getBombTarget()

		if not part or not part.Parent or part == selectedBomb or SW.has(part) then
			SW.say(FX.L("btn_bomb_none"), THEME.Danger)
			flashAdd(FX.L("btn_bomb_none"))
			playUI("Error")
			return
		end

		local att = Instance.new("Attachment")
		att.Name = "SwarmAtt"
		att.Parent = part

		local lv = Instance.new("LinearVelocity")
		lv.Name = "SwarmLV"
		lv.Attachment0 = att
		lv.MaxForce = math.huge
		lv.VectorVelocity = Vector3.zero
		lv.Parent = part

		local ao = Instance.new("AlignOrientation")
		ao.Name = "SwarmAO"
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.Attachment0 = att
		ao.MaxTorque = math.huge
		ao.Responsiveness = 200
		ao.CFrame = part.CFrame - part.CFrame.Position
		ao.Parent = part

		table.insert(SW.bombs, {
			part = part,
			att = att,
			lv = lv,
			ao = ao,
			cc = part.CanCollide,
			phase = "orbit",
			joinT0 = os.clock(),
			dir = Vector3.new(0, 1, 0),
			speed = 0,
			spd = SCATTER_SPEED,
			t0 = 0,
			attackAt = 0,
			atkT0 = 0,
			tr = part.Transparency,
			lastPos = part.Position,
			hits = 0,
			cT0 = 0,
			rdir = Vector3.new(0, 1, 0),
			tgt = nil,
		})

		part.CanCollide = false

		SW.slowT0 = os.clock()

		playUI("On")
		SW.say(FX.L("sw_added"), HUD_GREEN)
		SW.refresh()
	end

	function SW.clear()
		if droneActive or editMode then
			return
		end

		for _, b in ipairs(SW.bombs) do
			SW.release(b)
		end

		table.clear(SW.bombs)

		if SW.mode == "swarm" then
			SW.lockOn = false
			SW.lockRoot = nil
		end

		SW.spinUntil = nil

		playUI("Off")
		SW.say(FX.L("sw_cleared"), THEME.Warn)
		SW.refresh()
	end

	function SW.launchSwarm()
		local orbiters = SW.orbiters()

		if #orbiters == 0 then
			SW.say(FX.L("sw_empty"), THEME.Warn)
			playUI("Error")
			return
		end

		if not (SW.lockOn and SW.lockRoot and SW.lockRoot.Parent) then
			if not SW.setLock(true) then
				return
			end
		end

		local now = os.clock()
		local me = SW.playerRoot()
		local center = me and (me.Position + Vector3.new(0, Cfg.swarmHeight, 0)) or Camera.CFrame.Position
		local n = #orbiters

		for _, b in ipairs(orbiters) do
			local d = b.part.Position - center

			b.sa = math.atan2(d.Z, d.X)
		end

		table.sort(orbiters, function(x, y)
			return x.sa < y.sa
		end)

		local base = orbiters[1].sa
		local ringH = math.max(Cfg.swarmHeight * 0.5, 6)

		for i, b in ipairs(orbiters) do
			local a = base + (i - 1) * (2 * math.pi / n)

			b.sp0 = b.part.Position
			b.sp1 = center + Vector3.new(math.cos(a) * Cfg.swarmSpread, ringH, math.sin(a) * Cfg.swarmSpread)
			b.t0 = now
			b.attackAt = now + Cfg.swarmScatter
			b.speed = 0
			b.phase = "scatter"
		end

		SW.gapUntil = 0

		playUI("On")
		SW.say(FX.L("sw_go"), THEME.Danger)
		SW.refresh()
	end

	function SW.face(dir)
		local up = math.abs(dir.Y) > 0.97 and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)

		return CFrame.lookAt(Vector3.zero, dir, up)
	end

	function SW.groundPoint(root)
		local aim = getAimPoint(root)
		local skip = { root.Parent }

		if LP.Character then
			table.insert(skip, LP.Character)
		end

		for _, o in ipairs(SW.bombs) do
			if o.part then
				table.insert(skip, o.part)
			end
		end

		local params = RaycastParams.new()

		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = skip

		local res = workspace:Raycast(aim, Vector3.new(0, -800, 0), params)
		local y = res and res.Position.Y or (aim.Y - 6)

		return Vector3.new(aim.X, y - 1.5, aim.Z)
	end

	function SW.holdSlot(b, aim, vel)
		if not b.hs then
			local used = {}

			for _, o in ipairs(SW.bombs) do
				if o ~= b and o.hs and (o.phase == "climb" or o.phase == "hold") then
					used[o.hs] = true
				end
			end

			local k = 1

			while used[k] do
				k += 1
			end

			b.hs = k
		end

		local SPACE = 14
		local j = b.hs - 2
		local off = Vector3.zero
		local layer = 0

		if j >= 0 then
			layer = math.floor(j / 6)

			local a = (j % 6) * (math.pi / 3)

			off = Vector3.new(math.cos(a) * SPACE, 0, math.sin(a) * SPACE)
		end

		return Vector3.new(
			aim.X + vel.X * 0.4 + off.X,
			aim.Y + Cfg.nHeight + layer * SPACE,
			aim.Z + vel.Z * 0.4 + off.Z
		)
	end

	function SW.startClimb(b, now)
		SW.stopSpin(b)

		SW.slotN = (SW.slotN or 0) + 1

		b.slot = SW.slotN
		b.phase = "climb"
		b.stage = 1
		b.cl0 = now
		b.speed = 30
		b.cy0 = b.part.Position.Y
		b.hs = nil
		b.atkT0 = now
		b.part.CanCollide = false
	end

	function SW.gone(b)
		local p = b.part

		if not p or not p:IsDescendantOf(workspace) then
			return true
		end

		if (b.phase == "attack" or b.phase == "retreat") and b.tr < 0.9 and p.Transparency >= 0.99 then
			return true
		end

		return false
	end

	function SW.alive(root)
		local model = root and root.Parent
		local hum = model and model:FindFirstChildOfClass("Humanoid")

		return hum ~= nil and hum.Health > 0
	end

	function SW.pickFor(b)
		local list = SW.list()
		local free = {}

		for _, e in ipairs(list) do
			local used = false

			for _, o in ipairs(SW.bombs) do
				if o ~= b and o.tgt == e.root and (o.phase == "burst" or o.phase == "climb" or o.phase == "hold" or o.phase == "attack" or o.phase == "retreat") then
					used = true
					break
				end
			end

			if not used then
				table.insert(free, e)
			end
		end

		local pool = #free > 0 and free or list

		if #pool == 0 then
			return nil
		end

		return pool[math.random(#pool)].root
	end

	function SW.burstPos(b, p, tt)
		local e = p * p * (3 - 2 * p)
		local r = b.r0 + (b.R1 - b.r0) * e
		local a = b.a0 + b.sgn * math.rad(Cfg.scSpin) * tt

		return b.center + Vector3.new(math.cos(a) * r, b.dh * e, math.sin(a) * r)
	end

	function SW.launchScatter()
		SW.syncMode()

		if SW.mode ~= "scatter" or SW.mode ~= SW.wantMode then
			SW.say(FX.L("or_busy"), THEME.Warn)
			playUI("Error")
			return
		end

		local orbiters = SW.orbiters()

		if #orbiters == 0 then
			SW.say(FX.L("sw_empty"), THEME.Warn)
			playUI("Error")
			return
		end

		local list = SW.list()

		if #list == 0 then
			SW.say(FX.L("m_notarget"), THEME.Danger)
			playUI("Error")
			return
		end

		for i = #list, 2, -1 do
			local j = math.random(i)

			list[i], list[j] = list[j], list[i]
		end

		local now = os.clock()
		local me = SW.playerRoot()
		local center = me and (me.Position + Vector3.new(0, Cfg.swarmHeight, 0)) or Camera.CFrame.Position
		local sgn = (math.random() < 0.5) and 1 or -1

		for i, b in ipairs(orbiters) do
			local d = b.part.Position - center
			local flat = Vector3.new(d.X, 0, d.Z)

			b.tgt = list[(i - 1) % #list + 1].root
			b.center = center
			b.a0 = flat.Magnitude > 0.5 and math.atan2(d.Z, d.X) or (i - 1) * (2 * math.pi / #orbiters)
			b.r0 = math.max(flat.Magnitude, 2)
			b.R1 = Cfg.scDist * (0.8 + math.random() * 0.4)
			b.dh = 8 + (math.random() * 2 - 1) * 12
			b.sgn = sgn
			b.t0 = now
			b.attackAt = now + Cfg.scTime
			b.hits = 0
			b.phase = "burst"
		end

		SW.gapUntil = 0

		playUI("On")
		SW.say(FX.L("sc_go"), THEME.Danger)
		SW.refresh()
	end

	function SW.attackOrbit()
		SW.syncMode()

		if SW.mode == "swarm" or SW.mode == "scatter" or SW.mode ~= SW.wantMode then
			SW.say(FX.L("or_busy"), THEME.Warn)
			playUI("Error")
			return
		end

		if not (SW.lockOn and SW.lockRoot and SW.lockRoot.Parent) then
			SW.say(FX.L("or_pick"), THEME.Warn)
			playUI("Error")
			return
		end

		if #SW.orbiters() == 0 then
			SW.say(FX.L("sw_empty"), THEME.Warn)
			playUI("Error")
			return
		end

		if SW.spinUntil then
			return
		end

		SW.spinT0 = os.clock()
		SW.spinDur = (SW.mode == "tornado") and Cfg.tnDelay or Cfg.tgtDelay
		SW.spinUntil = SW.spinT0 + SW.spinDur

		playUI("On")
		SW.say(FX.L("or_spin"), THEME.Danger)
		SW.refresh()
	end

	function SW.pickPlayer(plr)
		if droneActive or editMode then
			return
		end

		SW.syncMode()

		if SW.mode == "swarm" or SW.mode == "scatter" or SW.mode ~= SW.wantMode then
			SW.say(FX.L("or_busy"), THEME.Warn)
			playUI("Error")
			return
		end

		local model = plr.Character
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		local root = model and (
			model:FindFirstChild("HumanoidRootPart")
			or model:FindFirstChild("Torso")
			or model:FindFirstChild("UpperTorso")
			or model:FindFirstChild("Head")
		)

		if not hum or hum.Health <= 0 or not root then
			SW.say(FX.L("m_notarget"), THEME.Danger)
			playUI("Error")

			if SW.buildList then
				SW.buildList()
			end

			return
		end

		SW.lockRoot = root
		SW.lockOn = true
		SW.spinUntil = nil

		SW.say(FX.L("or_set"), THEME.Danger)
		playUI("On")
		SW.refresh()
	end

	function SW.launch()
		if droneActive or editMode then
			return
		end

		SW.syncMode()

		if SW.mode == "scatter" then
			SW.launchScatter()
		elseif SW.mode ~= "swarm" then
			SW.attackOrbit()
		else
			SW.launchSwarm()
		end
	end

	SW.onLock = function()
		if droneActive or editMode then
			return
		end

		SW.setLock(not SW.lockOn)
	end

	SW.onNext = SW.cycle
	SW.onAdd = SW.add
	SW.onClear = SW.clear
	SW.onLaunch = SW.launch

	SW.addButton.Activated:Connect(function()
		SW.add()
	end)

	SW.clearButton.Activated:Connect(function()
		SW.clear()
	end)

	SW.addButton2.Activated:Connect(function()
		SW.add()
	end)

	SW.clearButton2.Activated:Connect(function()
		SW.clear()
	end)

	SW.attackButton.Activated:Connect(function()
		if droneActive or editMode then
			return
		end

		SW.attackOrbit()
	end)

	SW.refreshButton.Activated:Connect(function()
		SW.buildList()
	end)

	SW.addButton3.Activated:Connect(function()
		SW.add()
	end)

	SW.clearButton3.Activated:Connect(function()
		SW.clear()
	end)

	SW.attackButton3.Activated:Connect(function()
		if droneActive or editMode then
			return
		end

		SW.attackOrbit()
	end)

	SW.refreshButton3.Activated:Connect(function()
		SW.buildList()
	end)

	SW.addButton4.Activated:Connect(function()
		SW.add()
	end)

	SW.clearButton4.Activated:Connect(function()
		SW.clear()
	end)

	SW.launchButton4.Activated:Connect(function()
		if droneActive or editMode then
			return
		end

		SW.launchScatter()
	end)

	conns[#conns + 1] = UIS.InputBegan:Connect(function(input, gp)
		if gp or droneActive or editMode then
			return
		end

		local key = input.KeyCode

		if key == Enum.KeyCode.V then
			SW.add()
		elseif key == Enum.KeyCode.G then
			SW.launch()
		elseif key == Enum.KeyCode.L and #SW.bombs > 0 then
			SW.setLock(not SW.lockOn)
		elseif key == Enum.KeyCode.T and #SW.bombs > 0 then
			SW.cycle()
		end
	end)

	local lastT = os.clock()
	local uiT = 0

	function SW.syncMode()
		if SW.mode == SW.wantMode then
			return
		end

		for _, b in ipairs(SW.bombs) do
			if b.phase ~= "orbit" then
				return
			end
		end

		SW.mode = SW.wantMode
		SW.lockOn = false
		SW.lockRoot = nil
		SW.spinUntil = nil

		SW.refresh()
	end

	conns[#conns + 1] = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local dt = math.clamp(now - lastT, 0.001, 0.1)

		lastT = now

		local inSwarmTab = FX.page == "menu" and FX.tab >= 2 and FX.tab <= 5
		SW.panel.Visible = (not droneActive) and (#SW.bombs > 0 or editMode or inSwarmTab)

		if SW.msgLabel.Text ~= "" and now > SW.msgUntil then
			SW.msgLabel.Text = ""
		end

		SW.syncMode()

		local changed = false

		for i = #SW.bombs, 1, -1 do
			local b = SW.bombs[i]

			if SW.gone(b) then
				if b.phase == "attack" or b.phase == "retreat" then
					SW.explode(b.lastPos)
					SW.say(FX.L("sw_hit"), THEME.Danger)
					playUI("Error")
				end

				SW.release(b)
				table.remove(SW.bombs, i)
				changed = true
			else
				b.lastPos = b.part.Position
			end
		end

		if SW.lockOn then
			local model = SW.lockRoot and SW.lockRoot.Parent
			local hum = model and model:FindFirstChildOfClass("Humanoid")

			if not hum or hum.Health <= 0 then
				local list = SW.list()

				if SW.mode == "swarm" and list[1] then

					SW.lockRoot = list[1].root
					SW.say(FX.L("m_switched"), THEME.Danger)
				else
					SW.lockOn = false
					SW.lockRoot = nil

					if SW.recall() then
						SW.say(FX.L("sw_back"), THEME.Warn)
					elseif #SW.bombs > 0 then
						SW.say(FX.L("m_targetlost"), THEME.Warn)
					end

					if SW.buildList and FX.tab >= 3 then
						SW.buildList()
					end
				end

				changed = true
			end
		end

		if #SW.bombs == 0 then
			if SW.mode == "swarm" then
				SW.lockOn = false
				SW.lockRoot = nil
			end

			SW.spinUntil = nil
			box.Visible = false

			if changed then
				SW.refresh()
			end

			return
		end

		local me = SW.playerRoot()
		local tgtOk = SW.lockOn and SW.lockRoot and SW.lockRoot.Parent
		local aroundTarget = (SW.mode == "orbit" or SW.mode == "tornado") and tgtOk

		local spinK = 1
		local spinP = 0

		if SW.spinUntil then
			if not aroundTarget then
				SW.spinUntil = nil
			elseif now >= SW.spinUntil then
				SW.gapUntil = 0

				for _, b in ipairs(SW.bombs) do
					if b.phase == "orbit" then
						SW.startClimb(b, now)
					end
				end

				SW.spinUntil = nil
				spinK = SPIN_MULT
				spinP = 1
				changed = true
			else
				local p = math.clamp((now - SW.spinT0) / math.max(SW.spinDur, 0.5), 0, 1)

				spinP = p
				spinK = 1 + (SPIN_MULT - 1) * (p * p * (3 - 2 * p))
			end
		end

		local ring = {}

		for _, b in ipairs(SW.bombs) do
			if b.phase == "orbit" or b.phase == "pre" then
				table.insert(ring, b)

				if b.phase == "pre" then
					spinK = SPIN_MULT
					spinP = 1
				end
			end
		end

		local baseOrbit = Cfg.swarmOrbit

		if aroundTarget then
			baseOrbit = SW.mode == "tornado" and Cfg.tnSpeed or Cfg.tgtOrbit
		end

		local omega = math.rad(baseOrbit) * spinK

		if SW.slowT0 then
			local st = now - SW.slowT0

			if spinK ~= 1 or st >= ADD_SLOW_HOLD + ADD_SLOW_RAMP then
				SW.slowT0 = nil
			else
				local slowK = ADD_SLOW_K

				if st > ADD_SLOW_HOLD then
					local p = (st - ADD_SLOW_HOLD) / ADD_SLOW_RAMP

					p = p * p * (3 - 2 * p)
					slowK = ADD_SLOW_K + (1 - ADD_SLOW_K) * p
				end

				omega = omega * slowK
			end
		end

		SW.angle = (SW.angle + dt * omega) % (2 * math.pi)

		if #ring > 0 then
			local center, radius, cVel
			local tornado = aroundTarget and SW.mode == "tornado"

			if aroundTarget then

				center = getAimPoint(SW.lockRoot) + Vector3.new(0, tornado and (Cfg.tnLift - 2) or Cfg.tgtHeight, 0)
				radius = tornado and Cfg.tnRadius or Cfg.tgtDist
				cVel = SW.lockRoot.AssemblyLinearVelocity
			elseif me then
				center = me.Position + Vector3.new(0, Cfg.swarmHeight, 0)
				radius = Cfg.swarmRadius
				cVel = me.AssemblyLinearVelocity
			end

			if center then
				local gain = math.min(12, 0.8 / dt)
				local maxSpeed = ORBIT_APPROACH + cVel.Magnitude + radius * omega
				local amp = math.clamp(radius * 0.25, 2, 8)
				local squeeze = tornado and (1 - TN_SQUEEZE * spinP) or 1

				for k, b in ipairs(ring) do
					local a, desired, tang, dY

					if tornado then

						local frac = (#ring > 1) and ((k - 1) / (#ring - 1)) or 0
						local rk = (TN_BOTTOM + (1 - TN_BOTTOM) * frac) * radius * squeeze

						a = SW.angle + (k - 1) * 2.4
						desired = center + Vector3.new(math.cos(a) * rk, frac * Cfg.tnHeight, math.sin(a) * rk)
						tang = rk * omega
						dY = 0
					else

						a = SW.angle + (k - 1) * (2 * math.pi / #ring)

						local ph = a * WAVES + now * WAVE_SPEED

						dY = math.clamp(math.cos(ph) * amp * (WAVES * omega + WAVE_SPEED), -100, 100)
						desired = center + Vector3.new(math.cos(a) * radius, math.sin(ph) * amp, math.sin(a) * radius)
						tang = radius * omega
					end

					local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
					local v = (desired - b.part.Position) * gain + tangent * tang + Vector3.new(0, dY, 0) + cVel

					local limit = maxSpeed

					if b.joinT0 then
						local jp = (now - b.joinT0) / JOIN_TIME

						if jp >= 1 then
							b.joinT0 = nil
						else
							limit = math.min(maxSpeed, JOIN_SPEED + (maxSpeed - JOIN_SPEED) * jp * jp)
						end
					end

					if v.Magnitude > limit then
						v = v.Unit * limit
					end

					b.lv.VectorVelocity = v
					b.ao.CFrame = CFrame.lookAt(Vector3.zero, tangent)

					if b.phase == "pre" and now >= b.attackAt then
						SW.startClimb(b, now)
						changed = true
					end
				end
			else

				for _, b in ipairs(ring) do
					b.lv.VectorVelocity = Vector3.zero
				end
			end
		end

		for i = #SW.bombs, 1, -1 do
			local b = SW.bombs[i]
			local scat = SW.mode == "scatter"
			local root = scat and b.tgt or SW.lockRoot
			local rootOk

			if scat then
				rootOk = SW.alive(root)
			else
				rootOk = SW.lockOn and root and root.Parent
			end

			if scat and not rootOk and (b.phase == "burst" or b.phase == "climb" or b.phase == "hold" or b.phase == "attack" or b.phase == "retreat") then
				local nt = SW.pickFor(b)

				if nt then
					b.tgt = nt
					root = nt
					rootOk = true
					SW.say(FX.L("sc_lost"), THEME.Warn)
				else
					SW.stopSpin(b)
					b.phase = "orbit"
					b.part.CanCollide = false
					SW.say(FX.L("sw_back"), THEME.Warn)
					changed = true
				end
			end

			if b.phase == "scatter" then

				local t = now - b.t0
				local dur = math.max(Cfg.swarmScatter, 0.5)
				local function slotAt(tt)
					local p = math.clamp(tt / dur, 0, 1)
					local e = p * p * (3 - 2 * p)

					return b.sp0:Lerp(b.sp1, e)
				end

				local cur = slotAt(t)
				local nxt = slotAt(t + dt)
				local v = (nxt - cur) / dt + (cur - b.part.Position) * math.min(10, 0.8 / dt)

				if v.Magnitude > 600 then
					v = v.Unit * 600
				end

				b.lv.VectorVelocity = v

				local out = b.sp1 - b.sp0

				if out.Magnitude > 0.5 then
					b.ao.CFrame = SW.face(out.Unit)
				end

				if now >= b.attackAt then
					b.speed = 0

					if SW.lockOn and SW.lockRoot and SW.lockRoot.Parent then
						SW.startClimb(b, now)
					else
						b.dir = out.Magnitude > 0.5 and out.Unit or Vector3.new(0, 1, 0)
						b.phase = "ready"
					end
				end

			elseif b.phase == "burst" then

				local t = now - b.t0
				local dur = math.max(Cfg.scTime, 0.5)
				local cur = SW.burstPos(b, math.clamp(t / dur, 0, 1), t)
				local nxt = SW.burstPos(b, math.clamp((t + dt) / dur, 0, 1), t + dt)
				local v = (nxt - cur) / dt + (cur - b.part.Position) * math.min(10, 0.8 / dt)

				if v.Magnitude > 600 then
					v = v.Unit * 600
				end

				b.lv.VectorVelocity = v

				if v.Magnitude > 1 then
					b.ao.CFrame = CFrame.lookAt(Vector3.zero, v.Unit)
				end

				if now >= b.attackAt and rootOk then
					SW.startClimb(b, now)
					changed = true
				end

			elseif b.phase == "climb" then

				if rootOk then
					local aim = getAimPoint(root)
					local vel = root.AssemblyLinearVelocity
					local pos = b.part.Position
					local atk = scat and Cfg.scSpeed or Cfg.swarmSpeed
					local goal = SW.holdSlot(b, aim, vel)
					local to = goal - pos
					local flatV = Vector3.new(to.X, 0, to.Z)

					b.speed += (math.max(150, atk) - b.speed) * (1 - math.exp(-2.2 * dt))

					local w = math.clamp((goal.Y - pos.Y) / math.max(goal.Y - (b.cy0 or pos.Y), 1), 0, 1)

					w = w * w

					local d

					if flatV.Magnitude < 1 then
						d = to.Magnitude > 0.1 and to.Unit or Vector3.new(0, 1, 0)
					else
						d = (Vector3.new(0, 1, 0) * w + flatV.Unit * (1 - w))

						if goal.Y < pos.Y then
							d = to.Unit
						end

						d = d.Unit
					end

					local spd = math.min(b.speed, math.max(to.Magnitude * 3.5, 40))
					local vNew = b.lv.VectorVelocity:Lerp(d * spd, 1 - math.exp(-6 * dt))

					b.lv.VectorVelocity = vNew

					if vNew.Magnitude > 1 then
						b.ao.CFrame = SW.face(vNew.Unit)
					end

					if to.Magnitude < 8 or now - b.cl0 > 9 then

						b.phase = "hold"
						b.holdT = now
						changed = true
					end
				else
					b.phase = "orbit"
					b.part.CanCollide = false
				end

			elseif b.phase == "hold" then

				if rootOk then
					local aim = getAimPoint(root)
					local vel = root.AssemblyLinearVelocity
					local goal = SW.holdSlot(b, aim, vel)
					local v = (goal - b.part.Position) * 6

					if v.Magnitude > 200 then
						v = v.Unit * 200
					end

					b.lv.VectorVelocity = v + vel
					b.ao.CFrame = SW.face(Vector3.new(0, -1, 0))
				else
					b.phase = "orbit"
					b.part.CanCollide = false
				end

			elseif b.phase == "ready" then

				b.speed = b.speed * math.exp(-5 * dt)
				b.lv.VectorVelocity = b.dir * b.speed

				if SW.lockOn and SW.lockRoot and SW.lockRoot.Parent then
					local to = getAimPoint(SW.lockRoot) - b.part.Position

					if to.Magnitude > 0.5 then
						b.ao.CFrame = CFrame.lookAt(Vector3.zero, to.Unit)
					end
				end

			elseif b.phase == "retreat" then

				b.part.AssemblyAngularVelocity = Vector3.zero

				if rootOk then
					local gp = SW.groundPoint(root)
					local pos = b.part.Position
					local atk = scat and Cfg.scSpeed or Cfg.swarmSpeed

					if now - b.cT0 < 4 then
						local to = gp - pos
						local push = to.Magnitude > 0.05 and to.Unit or Vector3.new(0, -1, 0)

						b.lv.VectorVelocity = push * math.max(80, atk * 0.5)
						b.ao.CFrame = SW.face(push)
					else
						SW.startClimb(b, now)
						SW.say(FX.L("sc_retry"), THEME.Warn)
						changed = true
					end
				else
					SW.stopSpin(b)
					b.phase = "orbit"
					b.part.CanCollide = false
				end

			elseif b.phase == "attack" then

				b.part.AssemblyAngularVelocity = Vector3.zero

				if rootOk then
					local gp = SW.groundPoint(root)
					local pos = b.part.Position
					local to = gp - pos
					local dist = to.Magnitude
					local atk = scat and Cfg.scSpeed or Cfg.swarmSpeed

					b.speed += (atk - b.speed) * (1 - math.exp(-3.5 * dt))

					if dist < math.max(K.IMPACT_DIST, b.speed * dt * 1.5) or now - (b.dT0 or now) > 2.5 then
						b.cT0 = now
						b.hits += 1
						b.phase = "retreat"
					else

						b.dir = to.Unit
						b.lv.VectorVelocity = b.dir * b.speed
						b.ao.CFrame = SW.face(b.dir)
					end
				else
					SW.stopSpin(b)
					b.phase = "orbit"
					b.part.CanCollide = false
				end
			end
		end

		if now >= SW.gapUntil then
			local pick

			for _, b in ipairs(SW.bombs) do
				if b.phase == "hold" and (not pick or (b.hs or 99) < (pick.hs or 99)) then
					pick = b
				end
			end

			if pick then
				local scat = SW.mode == "scatter"
				local root = scat and pick.tgt or SW.lockRoot

				if root and root.Parent then
					local d = getAimPoint(root) - pick.part.Position
					local atk = scat and Cfg.scSpeed or Cfg.swarmSpeed

					pick.dir = d.Magnitude > 0.1 and d.Unit or Vector3.new(0, -1, 0)
					pick.speed = 60
					SW.startSpin(pick)
					pick.phase = "attack"
					pick.dT0 = now
					pick.part.CanCollide = pick.cc
					SW.gapUntil = now + Cfg.nGap
					changed = true
				end
			end
		end

		if #SW.bombs == 0 then
			if SW.mode == "swarm" then
				SW.lockOn = false
				SW.lockRoot = nil
			end

			SW.spinUntil = nil
			box.Visible = false
			SW.refresh()
			return
		end

		if (not droneActive) and SW.lockOn and SW.lockRoot and SW.lockRoot.Parent then
			local sp = Camera:WorldToViewportPoint(getAimPoint(SW.lockRoot))

			if sp.Z > 0 then
				box.Position = UDim2.fromOffset(sp.X, sp.Y)
				box.Visible = true
			else
				box.Visible = false
			end
		else
			box.Visible = false
		end

		uiT += dt

		if changed then
			uiT = 0
			SW.refresh()
		elseif uiT >= 0.15 then
			uiT = 0
			SW.refreshLive()
		end
	end)

	local CM = {
		state = "off",
		pos = Vector3.zero,
		look = Vector3.zero,
		fov = 70,
		origFov = 70,
		roll = 0,
		bomb = nil,
		shot = "chase",
		sa = 0,
		angle = 0,
		impactPos = nil,
		impactUntil = 0,
		shake = 0,
		retT0 = 0,
		dead = false,
	}

	FX.CM = CM

	local barGui = Instance.new("ScreenGui")
	barGui.Name = "DroneCinemaBars"
	barGui.ResetOnSpawn = false
	barGui.IgnoreGuiInset = true
	barGui.DisplayOrder = 50
	barGui.Parent = PlayerGui

	local function makeBar(top)
		local f = Instance.new("Frame")

		f.AnchorPoint = Vector2.new(0, top and 0 or 1)
		f.Position = UDim2.fromScale(0, top and 0 or 1)
		f.Size = UDim2.new(1, 0, 0, 0)
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BorderSizePixel = 0
		f.Parent = barGui

		return f
	end

	CM.barTop = makeBar(true)
	CM.barBot = makeBar(false)

	function CM.showBars(on, instant)
		local size = UDim2.new(1, 0, (on and Cfg.cineBars ~= false) and 0.115 or 0, 0)

		if instant then
			CM.barTop.Size = size
			CM.barBot.Size = size
		else
			tween(CM.barTop, 0.6, { Size = size })
			tween(CM.barBot, 0.6, { Size = size })
		end
	end

	function CM.rootOf(b)
		if SW.mode == "scatter" then
			return b.tgt
		end

		return SW.lockRoot
	end

	function CM.launched()
		for _, b in ipairs(SW.bombs) do
			if b.phase ~= "orbit" then
				return true
			end
		end

		return false
	end

	function CM.cf(p, l)
		local d = l - p

		if d.Magnitude < 0.05 then
			d = Vector3.new(0, 0, -1)
		end

		local up = math.abs(d.Unit.Y) > 0.985 and Vector3.new(math.cos(CM.sa), 0, math.sin(CM.sa)) or Vector3.new(0, 1, 0)

		return CFrame.lookAt(p, p + d, up)
	end

	function CM.pick(now)
		local cur = CM.bomb

		if cur then
			local still = false

			for _, b in ipairs(SW.bombs) do
				if b == cur then
					still = true
					break
				end
			end

			if still and (cur.phase == "attack" or cur.phase == "retreat") then
				return cur
			end

			if not still then

				local p = cur.part
				local exploded = p ~= nil and (not p:IsDescendantOf(workspace) or p.Transparency >= 0.99)

				CM.bomb = nil

				if exploded then
					CM.impactPos = cur.lastPos or CM.look
					CM.impactUntil = now + 0.9 * FX.slowK()
					CM.shake = 1

					return nil
				end
			else
				CM.bomb = nil
			end
		end

		local best, bestD

		for _, b in ipairs(SW.bombs) do
			if b.phase == "attack" or b.phase == "retreat" then
				local root = CM.rootOf(b)
				local d = (root and root.Parent) and (getAimPoint(root) - b.part.Position).Magnitude or 1e9

				if not bestD or d < bestD then
					best = b
					bestD = d
				end
			end
		end

		if best then
			CM.bomb = best
			CM.shot = "chase"
			CM.sa = math.random() * math.pi * 2
			CM.fix = nil

			local st = Cfg.cineStyle or "auto"

			if st == "random" then
				local pool = { "auto", "chase", "low", "top", "pov", "side", "orbit", "spiral", "wide", "flyby" }

				st = pool[math.random(#pool)]
			end

			CM.style = st
		end

		return best
	end

	function CM.hideUI()
		if CM.hidden then
			return
		end

		local h = { guis = {}, core = {}, controls = nil }

		CM.hidden = h

		for _, g in ipairs(PlayerGui:GetChildren()) do
			if g:IsA("ScreenGui") and g ~= barGui and g.Name ~= "DroneNoSignal" and g.Enabled then
				table.insert(h.guis, g)
				g.Enabled = false
			end
		end

		pcall(function()
			local sg = game:GetService("StarterGui")

			for _, t in ipairs({
				Enum.CoreGuiType.PlayerList,
				Enum.CoreGuiType.Backpack,
				Enum.CoreGuiType.Chat,
				Enum.CoreGuiType.Health,
				Enum.CoreGuiType.EmotesMenu,
			}) do
				if sg:GetCoreGuiEnabled(t) then
					table.insert(h.core, t)
					sg:SetCoreGuiEnabled(t, false)
				end
			end
		end)

		pcall(function()
			local ps = LP:FindFirstChild("PlayerScripts")
			local pm = ps and ps:FindFirstChild("PlayerModule")

			if pm then
				local controls = require(pm):GetControls()

				controls:Disable()
				h.controls = controls
			end
		end)
	end

	function CM.showUI()
		local h = CM.hidden

		if not h then
			return
		end

		CM.hidden = nil

		if h.controls then
			pcall(function()
				h.controls:Enable()
			end)
		end

		pcall(function()
			local sg = game:GetService("StarterGui")

			for _, t in ipairs(h.core) do
				sg:SetCoreGuiEnabled(t, true)
			end
		end)

		for _, g in ipairs(h.guis) do
			if g and g.Parent then
				g.Enabled = true
			end
		end
	end

	function CM.styleShot(st, bomb, bp, vel, aim, dir, height, sv, now, dt)
		local d = (Cfg.cineDist or 100) / 100
		local spd = math.clamp((bomb.speed or vel.Magnitude) / 600, 0, 1)
		local up = Vector3.new(0, 1, 0)

		if st == "chase" then
			return bp - dir * 26 * d + sv * 22 * d + Vector3.new(0, 2, 0) + vel * (0.85 / 9),
				bp + dir * 10 + vel * (0.85 / 12),
				62 + spd * 22, 9, 12, math.rad(7)
		elseif st == "low" then
			local ground = Vector3.new(aim.X, aim.Y - 3, aim.Z)

			return ground + sv * 42 * d + Vector3.new(0, 4, 0), bp,
				34 + math.clamp(height / 120, 0, 1) * 20, 5, 14, 0
		elseif st == "top" then
			return Vector3.new(aim.X, bp.Y + 30 * d, aim.Z) + sv * 0.5, aim, 60, 7, 10, 0
		elseif st == "pov" then
			return bp + dir * 3, bp + dir * 60, 80 + spd * 25, 45, 45, 0
		elseif st == "side" then
			local side = dir:Cross(up)

			side = side.Magnitude > 0.1 and side.Unit or sv

			return bp + side * 28 * d + Vector3.new(0, 3, 0) + vel * 0.08, bp + vel * 0.04, 55, 10, 14, 0
		elseif st == "orbit" then
			CM.angle = CM.angle + dt * 0.9

			local R = 45 * d

			return aim + Vector3.new(math.cos(CM.angle) * R, 10 + math.clamp(height * 0.25, 0, 40), math.sin(CM.angle) * R),
				bp, 55, 4, 10, 0
		elseif st == "spiral" then
			local a = now * 3
			local R = 16 * d

			return bp + Vector3.new(math.cos(a) * R, 3, math.sin(a) * R), bp + dir * 6, 70, 12, 14,
				math.sin(a) * math.rad(6)
		elseif st == "wide" then
			if not CM.fix then
				CM.fix = aim + sv * 85 * d + Vector3.new(0, 38 * d, 0)
			end

			return CM.fix, bp, 50, 4, 9, 0
		elseif st == "flyby" then
			if not CM.fix then
				CM.fix = aim + sv * 15 * d + Vector3.new(0, math.max(height * 0.5, 8), 0)
			end

			return CM.fix, bp + vel * 0.05, 48 + spd * 10, 6, 16, 0
		end

		return bp - dir * 26 + sv * 22, bp + dir * 10, 62, 9, 12, 0
	end

	function CM.begin(now)
		CM.state = "run"
		CM.origFov = Camera.FieldOfView
		CM.pos = Camera.CFrame.Position
		CM.look = Camera.CFrame.Position + Camera.CFrame.LookVector * 30
		CM.fov = Camera.FieldOfView
		CM.roll = 0
		CM.bomb = nil
		CM.impactPos = nil
		CM.impactUntil = 0
		CM.shake = 0
		CM.angle = math.random() * math.pi * 2
		CM.sa = math.random() * math.pi * 2

		Camera.CameraType = Enum.CameraType.Scriptable
		CM.showBars(true)
		CM.hideUI()
	end

	function CM.finish(releaseCamera)
		CM.state = "off"
		CM.bomb = nil
		CM.impactPos = nil

		if releaseCamera then
			Camera.CameraType = Enum.CameraType.Custom
			Camera.FieldOfView = CM.origFov
		end

		CM.showBars(false, not releaseCamera)
		CM.showUI()
	end

	function CM.step(dt)
		if CM.dead then
			return
		end

		local now = os.clock()
		local on = Cfg.cinema and not droneActive and not editMode
		local live = on and CM.launched()

		if droneActive or editMode then
			if CM.state ~= "off" then
				CM.finish(false)
			end

			return
		end

		if CM.state == "off" then
			if not live then
				return
			end

			CM.begin(now)
		end

		if CM.state == "return" then
			if live then
				CM.state = "run"
				CM.showBars(true)
			else
				local me = SW.playerRoot()

				if not me then
					CM.finish(true)
					return
				end

				local flat = Vector3.new(me.CFrame.LookVector.X, 0, me.CFrame.LookVector.Z)

				flat = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, -1)

				local tp = me.Position - flat * 12 + Vector3.new(0, 7, 0)
				local tl = me.Position + Vector3.new(0, 2, 0)
				local a = 1 - math.exp(-7 * dt)

				CM.pos = CM.pos:Lerp(tp, a)
				CM.look = CM.look:Lerp(tl, a)
				CM.fov += (CM.origFov - CM.fov) * a
				CM.roll += (0 - CM.roll) * a

				Camera.CFrame = CM.cf(CM.pos, CM.look) * CFrame.Angles(0, 0, CM.roll)
				Camera.FieldOfView = CM.fov

				if now - CM.retT0 > 0.9 or (CM.pos - tp).Magnitude < 3 then
					CM.finish(true)
				end

				return
			end
		end

		local holding = CM.impactPos ~= nil and now < CM.impactUntil
		local bomb = nil

		if not holding then
			bomb = CM.pick(now)

			holding = CM.impactPos ~= nil and now < CM.impactUntil
			if holding then
				bomb = nil
			end
		end

		if not live and not holding then
			CM.state = "return"
			CM.retT0 = now
			CM.showBars(false)
			return
		end

		local tp, tl, tFov, pRate, lRate
		local tRoll = 0
		local sv = Vector3.new(math.cos(CM.sa), 0, math.sin(CM.sa))

		if bomb then
			local root = CM.rootOf(bomb)
			local bp = bomb.part.Position
			local vel = bomb.part.AssemblyLinearVelocity
			local aim = (root and root.Parent) and getAimPoint(root) or bp
			local dir = vel.Magnitude > 5 and vel.Unit or (bomb.dir or Vector3.new(0, -1, 0))
			local height = bp.Y - aim.Y

			if height < 50 or bomb.phase == "retreat" then
				CM.shot = "low"
			end

			local st = CM.style or "auto"

			if st ~= "auto" then
				tp, tl, tFov, pRate, lRate, tRoll = CM.styleShot(st, bomb, bp, vel, aim, dir, height, sv, now, dt)
			elseif CM.shot == "chase" then

				tp = bp - dir * 26 + sv * 22 + Vector3.new(0, 2, 0)
				tl = bp + dir * 10
				tFov = 62 + math.clamp((bomb.speed or 0) / 600, 0, 1) * 22
				pRate = 9
				lRate = 12
				tRoll = math.rad(7)

				tp = tp + vel * (0.85 / pRate)
				tl = tl + vel * (0.85 / lRate)
			else

				local ground = Vector3.new(aim.X, aim.Y - 3, aim.Z)

				tp = ground + sv * 42 + Vector3.new(0, 4, 0)
				tl = bp
				tFov = 38 + math.clamp(height / 50, 0, 1) * 14
				pRate = 5
				lRate = 14
				tRoll = 0
			end
		elseif holding then

			local slow = FX.slowK()
			local dm = (Cfg.cineDist or 100) / 100

			tp = CM.impactPos + sv * 55 * dm + Vector3.new(0, 12 * dm, 0)
			tl = CM.impactPos + Vector3.new(0, 4, 0)
			tFov = 70 - (Cfg.slowmo or 0) * 6
			pRate = 2.5 / slow
			lRate = 5 / slow
			CM.shake = math.max(0, CM.shake - dt * 1.1 / slow)
		else

			local sum = Vector3.zero
			local n = 0

			for _, b in ipairs(SW.bombs) do
				if b.phase ~= "orbit" and b.part and b.part.Parent then
					sum += b.part.Position
					n += 1
				end
			end

			local c = n > 0 and (sum / n) or CM.look
			local spread = 0

			for _, b in ipairs(SW.bombs) do
				if b.phase ~= "orbit" and b.part and b.part.Parent then
					spread = math.max(spread, (b.part.Position - c).Magnitude)
				end
			end

			local R = math.clamp(55 + spread, 60, 160)

			CM.angle += dt * 0.3

			tp = c + Vector3.new(math.cos(CM.angle) * R, 12 + R * 0.22, math.sin(CM.angle) * R)
			tl = c + Vector3.new(0, 4, 0)
			tFov = 60
			pRate = 3
			lRate = 5
		end

		local ap = 1 - math.exp(-pRate * dt)
		local al = 1 - math.exp(-lRate * dt)

		CM.pos = CM.pos:Lerp(tp, ap)
		CM.look = CM.look:Lerp(tl, al)
		CM.fov += (tFov - CM.fov) * (1 - math.exp(-5 * dt))
		CM.roll += (tRoll * (CM.sa > math.pi and -1 or 1) - CM.roll) * (1 - math.exp(-3 * dt))

		local cf = CM.cf(CM.pos, CM.look)

		local k = CM.shake * ((Cfg.cineShake or 100) / 100)

		if k > 0.01 then
			local sx = math.noise(now * 30, 1.3, 0.2) * 1.4 * k
			local sy = math.noise(now * 33, 4.1, 2.7) * 1.4 * k
			local r = math.noise(now * 26, 7.7, 3.1) * math.rad(3) * k

			cf = cf * CFrame.new(sx, sy, 0) * CFrame.Angles(0, 0, r)
		end

		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame = cf * CFrame.Angles(0, 0, CM.roll)
		Camera.FieldOfView = CM.fov
	end

	pcall(function()
		RunService:UnbindFromRenderStep("XevrionCinema")
	end)

	RunService:BindToRenderStep("XevrionCinema", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local ok, err = pcall(CM.step, dt)

		if not ok then
			CM.dead = true
			warn("[XEVRION HUB] cinematic camera stopped: " .. tostring(err))

			pcall(function()
				CM.finish(not droneActive)
			end)
		end
	end)

	env.__SwarmStrikeCleanup = function()
		for _, c in ipairs(conns) do
			pcall(function()
				c:Disconnect()
			end)
		end

		pcall(function()
			RunService:UnbindFromRenderStep("XevrionCinema")
		end)

		if CM.state ~= "off" then
			pcall(function()
				Camera.CameraType = Enum.CameraType.Custom
				Camera.FieldOfView = CM.origFov
			end)
		end

		pcall(CM.showUI)

		pcall(function()
			barGui:Destroy()
		end)

		for _, b in ipairs(SW.bombs) do
			SW.release(b)
		end

		table.clear(SW.bombs)

		pcall(function()
			fxGui:Destroy()
		end)
	end

	SW.refresh()
end, function(err)
	warn("[XEVRION HUB] swarm / cinematic module error: " .. tostring(err))
end)

xpcall(function()
	local env = (getgenv and getgenv()) or _G

	if type(env.__DroneV2Cleanup) == "function" then
		pcall(env.__DroneV2Cleanup)
	end

	local V2 = FX.V2
	local conns = {}

	local MAX_BOMBS = 5
	local RING_R = 8
	local RING_BACK = 10
	local RING_SPIN = 200
	local FOLLOW_GAIN = 14
	local AXIS_SMOOTH = 14
	local SLOW_K = 0.2
	local SLOW_HOLD = 1.2
	local SLOW_RAMP = 1.6
	local JOIN_TIME = 2.2
	local JOIN_SPEED = 45
	local STRIKE_SPEED = 750
	local STRIKE_MAX = 3.5
	local UP_SPEED = 260
	local DIVE_SPEED = 330
	local FIN_MAX = 14

	local ROW_GAP = 7
	local LAUNCH_HEIGHT = 70
	local LAUNCH_TIME = 1.6
	local LAUNCH_SPEED = 230
	local LAUNCH_SPEED_MIN = 60
	local LAUNCH_RAMP = 0.8
	local RING_AFTER_LAUNCH = true
	local RING_BLEND_TIME = 1.0

	local rayParams = RaycastParams.new()

	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local lastT = os.clock()
	local lastWarn = 0

	local function face(dir)
		local up = math.abs(dir.Y) > 0.97 and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)

		return CFrame.lookAt(Vector3.zero, dir, up)
	end

	local function makeSat(part)
		local att = Instance.new("Attachment")

		att.Name = "V2Att"
		att.Parent = part

		local lv = Instance.new("LinearVelocity")

		lv.Name = "V2LV"
		lv.Attachment0 = att
		lv.MaxForce = math.huge
		lv.VectorVelocity = Vector3.zero
		lv.Parent = part

		local ao = Instance.new("AlignOrientation")

		ao.Name = "V2AO"
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.Attachment0 = att
		ao.MaxTorque = math.huge
		ao.Responsiveness = 200
		ao.CFrame = part.CFrame - part.CFrame.Position
		ao.Parent = part

		local s = {
			part = part,
			att = att,
			lv = lv,
			ao = ao,
			cc = part.CanCollide,
			tr = part.Transparency,
			phase = "form",
			lastPos = part.Position,
			joinT0 = os.clock(),
			born = os.clock(),
		}

		part.CanCollide = false

		return s
	end

	local function release(s)
		for _, key in ipairs({ "lv", "ao", "att" }) do
			local obj = s[key]

			if obj then
				pcall(function()
					obj:Destroy()
				end)

				s[key] = nil
			end
		end

		if s.part and s.part.Parent then
			pcall(function()
				s.part.CanCollide = s.cc
			end)
		end
	end

	local function gone(s)
		local p = s.part

		if not p or not p:IsDescendantOf(workspace) then
			return true
		end

		if s.tr < 0.9 and p.Transparency >= 0.99 and s.phase ~= "form" then
			return true
		end

		return false
	end

	local function alive(root)
		local model = root and root.Parent
		local hum = model and model:FindFirstChildOfClass("Humanoid")

		return hum ~= nil and hum.Health > 0
	end

	local function lift(p)
		local res = workspace:Raycast(p + Vector3.new(0, 6, 0), Vector3.new(0, -16, 0), rayParams)

		if res and p.Y < res.Position.Y + 3 then
			return Vector3.new(p.X, res.Position.Y + 3, p.Z)
		end

		return p
	end

	local function ground(pos)
		local res = workspace:Raycast(pos, Vector3.new(0, -800, 0), rayParams)
		local y = res and res.Position.Y or (pos.Y - 200)

		return Vector3.new(pos.X, y - 1.5, pos.Z)
	end

	function V2.count()
		return (V2.center and 1 or 0) + #V2.sats
	end

	function V2.has(part)
		if part == V2.center then
			return true
		end

		for _, s in ipairs(V2.sats) do
			if s.part == part then
				return true
			end
		end

		return false
	end

	function V2.paintBomb()
		local n = V2.count()

		if n >= MAX_BOMBS then
			bombButton.Text = FX.L("v2_ready")
		else
			bombButton.Text = FX.L("btn_bomb") .. " (" .. n .. "/" .. MAX_BOMBS .. ")"
		end

		if n > 0 then
			applyButtonStyle(bombButton, THEME.OnBase, THEME.Accent, 0.3)
		else
			applyButtonStyle(bombButton, THEME.Panel, THEME.Cyan, 0.75)
		end
	end

	local function flash(text, softOnly)
		bombButton.Text = text

		if softOnly then
			applyButtonStyle(bombButton, THEME.Panel, THEME.Warn, 0.3)
		else
			applyButtonStyle(bombButton, THEME.ErrorBase, THEME.Danger, 0.3)
		end

		task.delay(1, function()
			if V2.on and not droneActive then
				V2.paintBomb()
			end
		end)
	end

	function V2.clear()
		for _, s in ipairs(V2.sats) do
			release(s)
		end

		table.clear(V2.sats)

		V2.center = nil
		V2.axis = nil
		V2.slowT0 = nil
		V2.launching = false
		V2.ringBlend = 0

		if not droneActive then
			selectedBomb = nil
		end

		if V2.on then
			V2.paintBomb()
		end
	end

	function V2.select()
		if droneActive or editMode then
			return
		end

		local part = getBombTarget()

		if not part or not part.Parent then
			if V2.count() > 0 then
				V2.clear()
				playUI("Off")
				flash(FX.L("v2_cleared"), true)
			else
				playUI("Error")
				flash(FX.L("btn_bomb_none"))
			end

			return
		end

		if V2.has(part) or (SW.has and SW.has(part)) then
			playUI("Error")
			flash(FX.L("v2_dup"), true)
			return
		end

		if V2.count() >= MAX_BOMBS then
			playUI("Error")
			flash(FX.L("v2_ready"), true)
			return
		end

		pcall(FX.skinApply, part, Cfg.skinId)

		if not V2.center then
			V2.center = part
			V2.ctr = part.Transparency
			selectedBomb = part
		else
			table.insert(V2.sats, makeSat(part))
		end

		V2.slowT0 = os.clock()

		playUI("On")
		V2.paintBomb()
	end

	function V2.enter()
		if not droneActive then
			selectedBomb = nil
		end

		V2.paintBomb()
	end

	function V2.leave()
		if droneActive then
			return
		end

		V2.clear()
		resetBombButton()
	end

	function V2.releaseAll()
		for _, s in ipairs(V2.sats) do
			release(s)
		end

		for _, s in ipairs(V2.fin) do
			release(s)
		end

		table.clear(V2.sats)
		table.clear(V2.fin)

		V2.center = nil
		V2.flying = false
		V2.launching = false
	end

	function V2.onStart()
		if not selectedBomb then
			return
		end

		V2.center = selectedBomb
		V2.ctr = selectedBomb.Transparency
		V2.flying = true
		V2.lastRoot = nil
		V2.cPos = selectedBomb.Position
		V2.cVel = Vector3.zero

		V2.launching = true
		V2.launchT0 = os.clock()
		V2.launchY0 = selectedBomb.Position.Y
		V2.launchEnd = nil
		V2.ringBlend = 0

		showMessage(FX.L("v2_launch"), THEME.Warn)

		V2.paintBomb()
	end

	function V2.launchVel(now, part)
		if not V2.launching then
			return nil
		end

		local t = now - (V2.launchT0 or now)
		local rose = part.Position.Y - (V2.launchY0 or part.Position.Y)

		if t >= LAUNCH_TIME or rose >= LAUNCH_HEIGHT then
			V2.launching = false
			V2.launchEnd = now

			showMessage(FX.L("v2_ctrl"), HUD_GREEN)

			return nil
		end

		local k = math.clamp(t / LAUNCH_RAMP, 0, 1)

		k = k * k * (3 - 2 * k)

		return Vector3.new(0, LAUNCH_SPEED_MIN + (LAUNCH_SPEED - LAUNCH_SPEED_MIN) * k, 0)
	end

	V2.upCFrame = face(Vector3.new(0, 1, 0))

	function V2.cGone()
		local c = V2.center

		if not c then
			return false
		end

		if not c:IsDescendantOf(workspace) then
			return true
		end

		if V2.flying and (V2.ctr or 1) < 0.9 and c.Transparency >= 0.99 then
			return true
		end

		return false
	end

	function V2.beginFinish(exploded)
		local now = os.clock()
		local center = V2.center
		local pos = V2.cPos or (center and center.Position) or Vector3.zero

		local root = nil

		if V2.lastRoot and V2.lastRoot.Parent and alive(V2.lastRoot) then
			if (getAimPoint(V2.lastRoot) - pos).Magnitude < 45 then
				root = V2.lastRoot
			end
		end

		local csp = V2.cVel and V2.cVel.Magnitude or 0

		for i, s in ipairs(V2.sats) do
			s.born = now
			s.t0 = now
			s.tp = pos
			s.troot = root
			s.near = nil

			if exploded then
				s.phase = "strike"
				s.speed = math.max(220, csp)

				pcall(function()
					s.part.CanCollide = s.cc
				end)
			else
				s.phase = "up"
				s.t0 = now + (i - 1) * 0.05
				s.speed = 40
				s.ty = s.part.Position.Y + math.max(Cfg.nHeight, 50)
			end

			table.insert(V2.fin, s)
		end

		table.clear(V2.sats)

		V2.center = nil
		V2.flying = false
		V2.launching = false
		V2.ringBlend = 0
		V2.axis = nil
	end

	function V2.onStop(wasActive)
		if not V2.center then
			return
		end

		if lockEnabled and lockRoot and lockRoot.Parent then
			V2.lastRoot = lockRoot
		end

		if not V2.flying then

			V2.clear()
			return
		end

		V2.beginFinish(V2.cGone())
	end

	function V2.finStep(s, now, dt)
		if not s.lv or not s.ao then
			return
		end

		local pos = s.part.Position

		if s.phase == "strike" then
			local target

			if s.troot and s.troot.Parent and alive(s.troot) then
				target = getAimPoint(s.troot)
			else
				target = s.tp
			end

			local to = target - pos
			local dist = to.Magnitude
			local dir = dist > 0.05 and to.Unit or Vector3.new(0, -1, 0)

			s.speed = s.speed + (STRIKE_SPEED - s.speed) * (1 - math.exp(-6 * dt))

			s.lv.VectorVelocity = dir * math.min(s.speed, math.max(dist * 30, 90))
			s.ao.CFrame = face(dir)

			if dist < 4 then
				s.near = s.near or now
			else
				s.near = nil
			end

			if (s.near and now - s.near > 0.6) or now - s.t0 > STRIKE_MAX then
				s.phase = "up"
				s.t0 = now
				s.speed = 40
				s.ty = pos.Y + math.max(Cfg.nHeight, 50)

				pcall(function()
					s.part.CanCollide = false
				end)
			end
		elseif s.phase == "up" then
			if now < s.t0 then
				s.lv.VectorVelocity = Vector3.zero
				return
			end

			s.speed = s.speed + (UP_SPEED - s.speed) * (1 - math.exp(-2.2 * dt))

			s.lv.VectorVelocity = Vector3.new(0, s.speed, 0)
			s.ao.CFrame = face(Vector3.new(0, 1, 0))

			if pos.Y >= s.ty or now - s.t0 > 3.5 then
				s.phase = "dive"
				s.speed = 60
				s.d0 = now

				pcall(function()
					s.part.CanCollide = s.cc
				end)
			end
		elseif s.phase == "dive" then
			local to = ground(pos) - pos
			local dir = to.Magnitude > 0.05 and to.Unit or Vector3.new(0, -1, 0)

			s.speed = s.speed + (DIVE_SPEED - s.speed) * (1 - math.exp(-3.5 * dt))

			s.lv.VectorVelocity = dir * math.max(s.speed, 80)
			s.ao.CFrame = face(dir)

			if now - s.d0 > 4 then
				s.phase = "up"
				s.t0 = now
				s.speed = 40
				s.ty = pos.Y + math.max(Cfg.nHeight, 50)

				pcall(function()
					s.part.CanCollide = false
				end)
			end
		end
	end

	function V2.step(now, dt)

		local skip = {}

		if LP.Character then
			table.insert(skip, LP.Character)
		end

		if V2.center then
			table.insert(skip, V2.center)
		end

		for _, p in ipairs(FX.V2.satParts()) do
			table.insert(skip, p)
		end

		rayParams.FilterDescendantsInstances = skip

		local c = V2.center

		if c then
			if c:IsDescendantOf(workspace) then
				V2.cPos = c.Position
				V2.cVel = c.AssemblyLinearVelocity
			end

			if V2.flying and droneActive and lockEnabled and lockRoot and lockRoot.Parent then
				V2.lastRoot = lockRoot
			end

			if V2.cGone() then
				local wasFlying = V2.flying

				V2.beginFinish(true)

				if not wasFlying and not droneActive then
					selectedBomb = nil

					if V2.on then
						V2.paintBomb()
					end
				end

				c = nil
			end
		end

		for i = #V2.sats, 1, -1 do
			local s = V2.sats[i]

			if gone(s) then
				FX.boom(s.lastPos, true)
				release(s)
				table.remove(V2.sats, i)

				if V2.on and not droneActive then
					V2.paintBomb()
				end
			else
				s.lastPos = s.part.Position
			end
		end

		if c and #V2.sats > 0 then
			local n = #V2.sats
			local cpos = c.Position
			local cvel = c.AssemblyLinearVelocity

			local look

			if V2.flying and droneActive then
				look = getLookVector()
			else
				look = Camera.CFrame.LookVector
			end

			if V2.axis then
				V2.axis = V2.axis:Lerp(look, 1 - math.exp(-AXIS_SMOOTH * dt))
			else
				V2.axis = look
			end

			if V2.axis.Magnitude < 0.05 then
				V2.axis = look
			end

			local axis = V2.axis.Unit
			local right = axis:Cross(Vector3.yAxis)

			if right.Magnitude < 0.05 then
				right = axis:Cross(Vector3.zAxis)
			end

			right = right.Unit

			local upv = right:Cross(axis)

			local blend = 0

			if RING_AFTER_LAUNCH and V2.flying and droneActive and not V2.launching and V2.launchEnd then
				local p = math.clamp((now - V2.launchEnd) / RING_BLEND_TIME, 0, 1)

				blend = p * p * (3 - 2 * p)
			end

			V2.ringBlend = blend

			local rowAim = c.CFrame - c.CFrame.Position
			local aim = rowAim

			if blend > 0 then
				aim = rowAim:Lerp(face(axis), blend)
			end

			local spin = math.rad(RING_SPIN) * blend

			if V2.slowT0 then
				local st = now - V2.slowT0

				if st >= SLOW_HOLD + SLOW_RAMP then
					V2.slowT0 = nil
				else
					local k = SLOW_K

					if st > SLOW_HOLD then
						local p = (st - SLOW_HOLD) / SLOW_RAMP

						p = p * p * (3 - 2 * p)
						k = SLOW_K + (1 - SLOW_K) * p
					end

					spin = spin * k
				end
			end

			V2.angle = ((V2.angle or 0) + spin * dt) % (2 * math.pi)

			local gain = math.min(FOLLOW_GAIN, 0.8 / dt)
			local maxSpeed = cvel.Magnitude * 1.3 + 260

			local rowSlot = { 1, -1, 2, -2 }

			for i, s in ipairs(V2.sats) do
				if s.lv and s.ao then
					local a = V2.angle + (i - 1) * (2 * math.pi / n)
					local ca = math.cos(a)
					local sa = math.sin(a)

					local rowPos = cpos + right * ((rowSlot[i] or i) * ROW_GAP)
					local desired = rowPos

					if blend > 0 then
						local ringPos = cpos - axis * RING_BACK + right * (ca * RING_R) + upv * (sa * RING_R)

						desired = rowPos:Lerp(ringPos, blend)
					end

					desired = lift(desired)

					local tangent = right * (-sa) + upv * ca
					local v = (desired - s.part.Position) * gain + cvel + tangent * (RING_R * spin)

					local limit = maxSpeed

					if s.joinT0 then
						local jp = (now - s.joinT0) / JOIN_TIME

						if jp >= 1 then
							s.joinT0 = nil
						else
							limit = math.min(maxSpeed, JOIN_SPEED + (maxSpeed - JOIN_SPEED) * jp * jp)
						end
					end

					if v.Magnitude > limit then
						v = v.Unit * limit
					end

					s.lv.VectorVelocity = v
					s.ao.CFrame = aim
				end
			end
		end

		for i = #V2.fin, 1, -1 do
			local s = V2.fin[i]

			if gone(s) then
				FX.boom(s.lastPos, true)
				release(s)
				table.remove(V2.fin, i)
			elseif now - s.born > FIN_MAX then
				release(s)
				table.remove(V2.fin, i)
			else
				s.lastPos = s.part.Position
				V2.finStep(s, now, dt)
			end
		end
	end

	conns[#conns + 1] = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local dt = math.clamp(now - lastT, 0.001, 0.1)

		lastT = now

		if #V2.sats == 0 and #V2.fin == 0 and not V2.center then
			return
		end

		local ok, err = pcall(V2.step, now, dt)

		if not ok and now - lastWarn > 3 then
			lastWarn = now
			warn("[XEVRION HUB] DRONE V2 error: " .. tostring(err))
		end
	end)

	env.__DroneV2Cleanup = function()
		for _, cn in ipairs(conns) do
			pcall(function()
				cn:Disconnect()
			end)
		end

		pcall(V2.releaseAll)
	end
end, function(err)
	warn("[XEVRION HUB] DRONE V2 module error: " .. tostring(err))
end)

LP.CharacterAdded:Connect(function()
	stopDrone()

	task.wait(0.5)

	Camera.CameraType = Enum.CameraType.Custom
end)

function FX.syncUI()
	for key, setter in pairs(FX.setters) do
		setter(Cfg[key], true)
	end

	for _, refresh in pairs(FX.togglers) do
		refresh()
	end

	FX.applyLang()
end

function FX.applySettings(t)
	local function num(v, lo, hi, def)
		v = tonumber(v)

		if not v then
			return def
		end

		return math.clamp(v, lo, hi)
	end

	K.SPEED = math.clamp(math.floor(num(t.speed, K.MIN_SPEED, K.MAX_SPEED, K.SPEED) / K.SPEED_STEP + 0.5) * K.SPEED_STEP, K.MIN_SPEED, K.MAX_SPEED)

	Cfg.fov = num(t.fov, 40, 110, Cfg.fov)
	Cfg.camDist = num(t.camDist, 10, 60, Cfg.camDist)
	Cfg.sens = num(t.sens, 20, 300, Cfg.sens)
	Cfg.boost = num(t.boost, 125, 400, Cfg.boost)
	Cfg.swarmMax = math.floor(num(t.swarmMax, 1, 8, Cfg.swarmMax) + 0.5)
	Cfg.swarmScatter = num(t.swarmScatter, 1, 6, Cfg.swarmScatter)
	Cfg.swarmSpeed = num(t.swarmSpeed, 100, 800, Cfg.swarmSpeed)
	Cfg.swarmHeight = num(t.swarmHeight, 5, 30, Cfg.swarmHeight)
	Cfg.swarmRadius = num(t.swarmRadius, 4, 30, Cfg.swarmRadius)
	Cfg.tgtDist = num(t.tgtDist, 30, 60, Cfg.tgtDist)
	Cfg.tgtOrbit = num(t.tgtOrbit, 30, 240, Cfg.tgtOrbit)
	Cfg.tgtDelay = num(t.tgtDelay, 0, 6, Cfg.tgtDelay)
	Cfg.tnRadius = num(t.tnRadius, 20, 60, Cfg.tnRadius)
	Cfg.tnHeight = num(t.tnHeight, 10, 50, Cfg.tnHeight)
	Cfg.tnSpeed = num(t.tnSpeed, 60, 360, Cfg.tnSpeed)
	Cfg.tnDelay = num(t.tnDelay, 0, 6, Cfg.tnDelay)

	if tonumber(t.ver) ~= 25 then
		Cfg.tgtDelay = 0
		Cfg.tnDelay = 0
	end
	Cfg.tgtHeight = num(t.tgtHeight, 0, 40, Cfg.tgtHeight)
	Cfg.tnLift = num(t.tnLift, 0, 40, Cfg.tnLift)
	Cfg.spinPower = num(t.spinPower, 250, 5000, Cfg.spinPower)
	Cfg.swarmOrbit = num(t.swarmOrbit, 20, 240, Cfg.swarmOrbit)
	Cfg.swarmSpread = num(t.swarmSpread, 15, 100, Cfg.swarmSpread)
	Cfg.scTime = num(t.scTime, 1, 6, Cfg.scTime)
	Cfg.scDist = num(t.scDist, 30, 150, Cfg.scDist)
	Cfg.scSpin = num(t.scSpin, 90, 720, Cfg.scSpin)
	Cfg.scSpeed = num(t.scSpeed, 100, 800, Cfg.scSpeed)
	Cfg.nHeight = num(t.nHeight, 30, 250, Cfg.nHeight)
	Cfg.nGap = num(t.nGap, 0.5, 5, Cfg.nGap)

	if t.lang == "EN" or t.lang == "ID" then
		Cfg.lang = t.lang
	end

	if table.find(FX.RADAR_RANGES, tonumber(t.radarRange)) then
		Cfg.radarRange = tonumber(t.radarRange)
	end

	Cfg.sndVol = num(t.sndVol, 0, 300, Cfg.sndVol)
	Cfg.shake = num(t.shake, 0, 300, Cfg.shake)
	Cfg.slowmo = math.floor(num(t.slowmo, 0, 3, Cfg.slowmo) + 0.5)
	Cfg.trailSize = num(t.trailSize, 50, 300, Cfg.trailSize)
	Cfg.swarmFx = math.floor(num(t.swarmFx, 0, 2, Cfg.swarmFx) + 0.5)
	Cfg.cineShake = num(t.cineShake, 0, 200, Cfg.cineShake)
	Cfg.cineDist = num(t.cineDist, 50, 200, Cfg.cineDist)

	if type(t.sndPack) == "string" and FX.sndById[t.sndPack] then
		Cfg.sndPack = t.sndPack
	end

	if type(t.trailId) == "string" and FX.trailById[t.trailId] then
		Cfg.trailId = t.trailId
	end

	if type(t.cineStyle) == "string" and FX.cineById[t.cineStyle] then
		Cfg.cineStyle = t.cineStyle
	end

	if type(t.sndCustom) == "string" then
		Cfg.sndCustom = string.match(t.sndCustom, "%d+") or ""
	end

	Cfg.lagLevel = math.floor(num(t.lagLevel, 0, 3, Cfg.lagLevel) + 0.5)
	Cfg.fxSize = num(t.fxSize, 25, 400, Cfg.fxSize)
	Cfg.fxTime = num(t.fxTime, 50, 300, Cfg.fxTime)
	Cfg.fxColor = math.floor(num(t.fxColor, 0, #FX.FXCOLORS - 1, Cfg.fxColor) + 0.5)

	if type(t.fxId) == "string" and FX.fxById[t.fxId] then
		Cfg.fxId = t.fxId
	end

	if type(t.skinId) == "string" and FX.skinById[t.skinId] then
		Cfg.skinId = t.skinId
	end

	if type(t.skinCustom) == "string" then
		Cfg.skinCustom = string.match(t.skinCustom, "%d+") or ""
	end

	for _, key in ipairs({ "friendCheck", "speedFx", "noSignal", "swarmCollapsed", "cinema", "autoLag", "cineBars" }) do
		if type(t[key]) == "boolean" then
			Cfg[key] = t[key]
		end
	end

	updateSpeedUI()
	FX.syncUI()

	if Cfg.lagLevel > 0 and FX.LAG.applied ~= Cfg.lagLevel then
		FX.lagApply(Cfg.lagLevel)
	end

	FX.skinApplyAll()
	FX.trailApplyAll()
end

local function loadLayoutLocal()
	local applied = false

	local function apply()
		if applied then
			return
		end

		if Store.dirty then
			applied = true
			return
		end

		local raw, source = Store.read()

		if not raw then
			return
		end

		local ok, data = pcall(function()
			return game:GetService("HttpService"):JSONDecode(raw)
		end)

		if not ok or type(data) ~= "table" then
			warn("[XEVRION HUB] saved layout is not valid JSON")
			return
		end

		applied = true

		local count = 0

		for id, v in pairs(data) do
			if ELEMENTS[id] and type(v) == "table" and tonumber(v.x) and tonumber(v.y) then
				layout[id] = {
					x = math.clamp(tonumber(v.x), 0, 1),
					y = math.clamp(tonumber(v.y), 0, 1),
					s = math.clamp(tonumber(v.s) or 1, K.MIN_LAYOUT_SCALE, K.MAX_LAYOUT_SCALE),
				}
				count += 1
			end
		end

		if type(data._settings) == "table" then
			FX.applySettings(data._settings)
		end

		applyAll()
	end

	pcall(function()
		game:GetService("LocalStorageService"):WhenLoaded(apply)
	end)

	apply()

	for _, t in ipairs({ 0.5, 1.5, 3, 6 }) do
		task.delay(t, apply)
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LP then
		FX.askFriend(p)
	end
end

FX.conn(Players.PlayerAdded, function(p)
	FX.askFriend(p)
end)

refreshDroneButton()
resetBombButton()
setStatus(false)
updateSpeedUI()
refreshLockUI()
updateLayoutForViewport()
applyAll()

loadLayoutLocal()

-- ============================================================
-- XEVRION HUB  |  DAILY HOLD VERIFICATION  (added in FIX5)
-- Hold the button until the energy bar is full. If you let go the
-- energy drains. Needed once every 24 hours, then the menu opens.
-- ============================================================
FX.gate = function()
	local HOLD_SECONDS = 10 -- time holding to fill the bar
	local DRAIN_SECONDS = 6 -- time for a full bar to empty after letting go
	local COOLDOWN = 24 * 60 * 60 -- seconds between verifications
	local FILE = "XEVRION_HUB_verify.json"
	local KEY = "XEVRION_HUB_verify_v1"

	local ENERGY_IMAGE = "rbxassetid://70527201304547" -- energy icon
	local BACKGROUND_IMAGE = "rbxassetid://108046279268110" -- panel background

	local HttpService = game:GetService("HttpService")

	local function readStamp()
		local raw

		if type(readfile) == "function" and type(isfile) == "function" then
			local okEx, exists = pcall(isfile, FILE)

			if okEx and exists then
				local okRd, r = pcall(readfile, FILE)

				if okRd and type(r) == "string" and r ~= "" then
					raw = r
				end
			end
		end

		if not raw then
			local okLs, r = pcall(function()
				return game:GetService("LocalStorageService"):GetItem(KEY)
			end)

			if okLs and type(r) == "string" and r ~= "" then
				raw = r
			end
		end

		if not raw then
			return nil
		end

		local okJ, data = pcall(function()
			return HttpService:JSONDecode(raw)
		end)

		if okJ and type(data) == "table" and tonumber(data.t) then
			return tonumber(data.t)
		end

		return nil
	end

	local function writeStamp(t)
		local okJ, json = pcall(function()
			return HttpService:JSONEncode({ t = t })
		end)

		if not okJ then
			return
		end

		if type(writefile) == "function" then
			pcall(writefile, FILE, json)
		end

		pcall(function()
			local store = game:GetService("LocalStorageService")

			store:SetItem(KEY, json)
			store:Flush()
		end)
	end

	-- valid = verified less than 24h ago (a time stamp from the future is ignored)
	local function isValid()
		local t = readStamp()

		if not t then
			return false
		end

		local now = os.time()

		return t <= now + 60 and now - t < COOLDOWN
	end

	if isValid() then
		setMenuOpen(true, true)

		return
	end

	FX.gateActive = true

	-- --------------------------------------------------------
	-- UI
	-- --------------------------------------------------------
	local WHITE = Color3.new(1, 1, 1)
	local DARK = Color3.fromRGB(18, 18, 24)
	local MUTED = Color3.fromRGB(190, 198, 222)

	local sg = Instance.new("ScreenGui")

	sg.Name = "XEVRION_VERIFY"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 1000
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = PlayerGui

	local dim = Instance.new("Frame")

	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Active = true -- blocks every click behind the panel
	dim.Parent = sg

	local card = Instance.new("CanvasGroup")

	card.Name = "Card"
	card.Size = UDim2.fromOffset(340, 262)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(60, 62, 72)
	card.BorderSizePixel = 0
	card.GroupTransparency = 1
	card.Active = true
	card.Parent = sg

	addCorner(card, 18)

	local cardStroke = addStroke(card, WHITE, 4, 0)
	local cardStrokeGrad = Instance.new("UIGradient")

	cardStrokeGrad.Color = RAINBOW
	cardStrokeGrad.Parent = cardStroke

	local cardScale = Instance.new("UIScale")

	cardScale.Scale = 0.8
	cardScale.Parent = card

	-- panel background image (sits behind everything)
	local cardBg = Instance.new("ImageLabel")

	cardBg.Name = "Background"
	cardBg.Size = UDim2.fromScale(1, 1)
	cardBg.BackgroundTransparency = 1
	cardBg.Image = BACKGROUND_IMAGE
	cardBg.ScaleType = Enum.ScaleType.Crop
	cardBg.ZIndex = 0
	cardBg.Parent = card

	local function fitScale()
		local v = sg.AbsoluteSize

		return math.clamp(math.min(v.X / 370, v.Y / 290), 0.5, 1.25)
	end

	local base = fitScale()

	sg:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		base = fitScale()
	end)

	-- header
	local header = Instance.new("Frame")

	header.Size = UDim2.new(1, 0, 0, 44)
	header.BackgroundColor3 = WHITE
	header.BorderSizePixel = 0
	header.Parent = card

	local headerGrad = Instance.new("UIGradient")

	headerGrad.Color = ColorSequence.new(Color3.fromRGB(255, 228, 118), Color3.fromRGB(245, 178, 46))
	headerGrad.Rotation = 90
	headerGrad.Parent = header

	local title = Instance.new("TextLabel")

	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Text = "HUMAN VERIFICATION"
	title.TextColor3 = WHITE
	title.TextSize = 18
	title.Font = Enum.Font.FredokaOne
	title.Parent = header

	do
		local s = addStroke(title, DARK, 2, 0)

		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	end

	local sub = Instance.new("TextLabel")

	sub.Size = UDim2.new(1, -20, 0, 18)
	sub.Position = UDim2.fromOffset(10, 52)
	sub.BackgroundTransparency = 1
	sub.Text = "Hold the button until the energy is full"
	sub.TextColor3 = MUTED
	sub.TextSize = 13
	sub.Font = Enum.Font.GothamBold
	sub.Parent = card

	-- pulse ring + hold button
	local BTN = 84

	local ring = Instance.new("Frame")

	ring.Size = UDim2.fromOffset(BTN, BTN)
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.new(0.5, 0, 0, 82 + BTN / 2)
	ring.BackgroundTransparency = 1
	ring.BorderSizePixel = 0
	ring.Parent = card

	addCorner(ring, BTN)

	local ringStroke = addStroke(ring, Color3.fromRGB(255, 200, 80), 3, 1)

	local button = Instance.new("TextButton")

	button.Name = "HoldButton"
	button.Size = UDim2.fromOffset(BTN, BTN)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.new(0.5, 0, 0, 82 + BTN / 2)
	button.BackgroundColor3 = Color3.fromRGB(38, 40, 48)
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = "HOLD"
	button.TextColor3 = WHITE
	button.TextSize = 18
	button.Font = Enum.Font.FredokaOne
	button.ZIndex = 3
	button.Parent = card

	addCorner(button, BTN)

	local btnStroke = addStroke(button, WHITE, 3, 0)
	local btnGrad = Instance.new("UIGradient")

	btnGrad.Color = RAINBOW
	btnGrad.Parent = btnStroke

	local btnScale = Instance.new("UIScale")

	btnScale.Parent = button

	do
		local s = addStroke(button, DARK, 2, 0)

		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	end

	-- energy bar
	local BAR_W, BAR_H, BAR_Y = 280, 26, 184

	local bar = Instance.new("Frame")

	bar.Size = UDim2.fromOffset(BAR_W, BAR_H)
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, BAR_Y)
	bar.BackgroundColor3 = Color3.fromRGB(24, 25, 32)
	bar.BorderSizePixel = 0
	bar.Parent = card

	addCorner(bar, BAR_H)
	addStroke(bar, DARK, 3, 0)

	local fill = Instance.new("CanvasGroup")

	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 70, 60)
	fill.BorderSizePixel = 0
	fill.ZIndex = 2
	fill.Parent = bar

	addCorner(fill, BAR_H)

	local gloss = Instance.new("Frame")

	gloss.Size = UDim2.fromScale(1, 0.45)
	gloss.BackgroundColor3 = WHITE
	gloss.BackgroundTransparency = 0.82
	gloss.BorderSizePixel = 0
	gloss.ZIndex = 3
	gloss.Parent = fill

	local stripe = Instance.new("Frame")

	stripe.Size = UDim2.new(0, 26, 1, 0)
	stripe.BackgroundColor3 = WHITE
	stripe.BackgroundTransparency = 0.65
	stripe.BorderSizePixel = 0
	stripe.ZIndex = 3
	stripe.Parent = fill

	-- energy cell separators (every 10%)
	for i = 1, 9 do
		local tick = Instance.new("Frame")

		tick.Size = UDim2.new(0, 2, 1, -8)
		tick.AnchorPoint = Vector2.new(0.5, 0.5)
		tick.Position = UDim2.new(i / 10, 0, 0.5, 0)
		tick.BackgroundColor3 = DARK
		tick.BackgroundTransparency = 0.35
		tick.BorderSizePixel = 0
		tick.ZIndex = 4
		tick.Parent = bar
	end

	local bolt = Instance.new("ImageLabel")

	bolt.Size = UDim2.fromOffset(34, 34)
	bolt.AnchorPoint = Vector2.new(0.5, 0.5)
	bolt.Position = UDim2.fromScale(0.04, 0.5)
	bolt.BackgroundTransparency = 1
	bolt.Image = ENERGY_IMAGE
	bolt.ScaleType = Enum.ScaleType.Fit
	bolt.ZIndex = 5
	bolt.Parent = bar

	local boltScale = Instance.new("UIScale")

	boltScale.Parent = bolt

	local pct = Instance.new("TextLabel")

	pct.Size = UDim2.fromScale(1, 1)
	pct.BackgroundTransparency = 1
	pct.Text = "0%"
	pct.TextColor3 = WHITE
	pct.TextSize = 14
	pct.Font = Enum.Font.FredokaOne
	pct.ZIndex = 6
	pct.Parent = bar

	do
		local s = addStroke(pct, DARK, 2, 0)

		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	end

	local status = Instance.new("TextLabel")

	status.Size = UDim2.new(1, -20, 0, 18)
	status.Position = UDim2.fromOffset(10, 220)
	status.BackgroundTransparency = 1
	status.Text = "Press and hold for 10 seconds"
	status.TextColor3 = MUTED
	status.TextSize = 13
	status.Font = Enum.Font.GothamBold
	status.Parent = card

	local note = Instance.new("TextLabel")

	note.Size = UDim2.new(1, -20, 0, 14)
	note.Position = UDim2.fromOffset(10, 241)
	note.BackgroundTransparency = 1
	note.Text = "Required once every 24 hours"
	note.TextColor3 = Color3.fromRGB(140, 149, 172)
	note.TextSize = 10
	note.Font = Enum.Font.GothamMedium
	note.Parent = card

	local flash = Instance.new("Frame")

	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = WHITE
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 20
	flash.Parent = card

	-- --------------------------------------------------------
	-- spark particles
	-- --------------------------------------------------------
	local sparks = {}
	local sparkPool = {}

	local function spawnSpark(x, y, color, fast)
		local f = table.remove(sparkPool)

		if not f then
			f = Instance.new("Frame")
			f.BorderSizePixel = 0
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.ZIndex = 8

			addCorner(f, 8)
		end

		local sz = math.random(3, 6)

		f.Size = UDim2.fromOffset(sz, sz)
		f.BackgroundColor3 = color
		f.BackgroundTransparency = 0
		f.Position = UDim2.fromOffset(x, y)
		f.Parent = card

		local sp = fast and math.random(60, 150) or math.random(25, 70)
		local ang = math.rad(math.random(0, 360))

		sparks[#sparks + 1] = {
			f = f,
			x = x,
			y = y,
			vx = fast and math.cos(ang) * sp or (math.random() - 0.5) * 50,
			vy = fast and math.sin(ang) * sp or -sp,
			life = fast and 0.8 or 0.65,
			age = 0,
		}
	end

	local function stepSparks(dt)
		for i = #sparks, 1, -1 do
			local p = sparks[i]

			p.age += dt

			if p.age >= p.life then
				p.f.Parent = nil
				sparkPool[#sparkPool + 1] = p.f
				table.remove(sparks, i)
			else
				p.x += p.vx * dt
				p.y += p.vy * dt
				p.vy += 40 * dt
				p.f.Position = UDim2.fromOffset(p.x, p.y)
				p.f.BackgroundTransparency = (p.age / p.life) ^ 1.5
			end
		end
	end

	-- --------------------------------------------------------
	-- logic
	-- --------------------------------------------------------
	local e = 0 -- real energy 0..1
	local ed = 0 -- smoothed value shown on screen
	local holding = false
	local holdInput = nil
	local done = false
	local closing = false
	local t = 0
	local sparkAcc = 0
	local loop = nil

	local function energyColor(v)
		return Color3.fromHSV(math.clamp(v, 0, 1) * 0.34, 0.85, 1)
	end

	local function finish(animated)
		if closing then
			return
		end

		closing = true
		FX.gateActive = false

		if loop then
			loop:Disconnect()
		end

		local function close()
			pcall(function()
				sg:Destroy()
			end)

			if not FX.dead then
				setMenuOpen(true, not animated)
			end
		end

		if animated then
			tween(card, 0.35, { GroupTransparency = 1 })
			tween(cardScale, 0.35, { Scale = base * 0.85 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			tween(dim, 0.35, { BackgroundTransparency = 1 })
			task.delay(0.4, close)
		else
			close()
		end
	end

	local function success()
		if done then
			return
		end

		done = true
		holding = false
		e = 1
		writeStamp(os.time())

		pcall(playUI, "Open")

		button.Text = "✓"
		status.Text = "VERIFIED  -  welcome!"
		status.TextColor3 = Color3.fromRGB(110, 235, 110)
		sub.Text = "You are human"

		flash.BackgroundTransparency = 0.2

		tween(flash, 0.6, { BackgroundTransparency = 1 })
		tween(cardScale, 0.12, { Scale = base * 1.08 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		task.delay(0.12, function()
			tween(cardScale, 0.3, { Scale = base }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)

		for _ = 1, 36 do
			spawnSpark(170, 124, energyColor(math.random()), true)
		end

		task.delay(1.2, function()
			finish(true)
		end)
	end

	button.InputBegan:Connect(function(input)
		if done or not isPress(input) then
			return
		end

		holding = true
		holdInput = input

		pcall(playUI, "Hover")
	end)

	FX.conn(UIS.InputEnded, function(input)
		if not holdInput then
			return
		end

		local isMouse = holdInput.UserInputType == Enum.UserInputType.MouseButton1

		if input == holdInput or (isMouse and input.UserInputType == Enum.UserInputType.MouseButton1) then
			holding = false
			holdInput = nil
		end
	end)

	pcall(function()
		UIS.WindowFocusReleased:Connect(function()
			holding = false
			holdInput = nil
		end)
	end)

	-- intro animation
	tween(dim, 0.35, { BackgroundTransparency = 0.4 })
	tween(card, 0.3, { GroupTransparency = 0 })
	tween(cardScale, 0.45, { Scale = base }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	loop = FX.conn(RunService.RenderStepped, function(dt)
		if closing then
			return
		end

		dt = math.min(dt, 0.1)
		t += dt

		stepSparks(dt)

		-- keep the panel scaled to the screen (not while the intro/outro tween runs)
		if t > 0.6 and not done then
			cardScale.Scale = base
		end

		if not done then
			if holding then
				e = math.min(1, e + dt / HOLD_SECONDS)
			else
				e = math.max(0, e - dt / DRAIN_SECONDS)
			end

			if e >= 1 then
				success()
			end
		end

		ed += (e - ed) * math.min(1, dt * 14)

		local col = energyColor(ed)

		fill.Size = UDim2.fromScale(math.clamp(ed, 0, 1), 1)
		fill.BackgroundColor3 = col
		pct.Text = string.format("%d%%", math.floor(ed * 100 + 0.5))

		-- moving shine inside the energy
		local speed = holding and 2.4 or 0.8
		local fw = fill.AbsoluteSize.X / math.max(cardScale.Scale, 0.01)

		stripe.Position = UDim2.fromOffset(((t * speed) % 1.5 - 0.3) * fw, 0)
		stripe.Visible = ed > 0.03

		-- bolt rides the tip of the energy
		bolt.Position = UDim2.fromScale(math.clamp(ed, 0.045, 0.955), 0.5)
		boltScale.Scale = (holding and 1.15 or 0.9) + math.sin(t * (holding and 18 or 4)) * (holding and 0.14 or 0.04)
		bolt.Rotation = holding and math.sin(t * 22) * 10 or 0

		-- spinning rainbow outline
		btnGrad.Rotation = (t * 120) % 360
		cardStrokeGrad.Rotation = (t * 40) % 360

		-- button feel
		local targetS = holding and 0.9 or (1 + math.sin(t * 3) * 0.03)

		btnScale.Scale += (targetS - btnScale.Scale) * math.min(1, dt * 16)
		button.BackgroundColor3 = Color3.fromRGB(38, 40, 48):Lerp(col, holding and 0.45 or ed * 0.25)

		-- pulse ring
		if holding and not done then
			local p = (t * 1.3) % 1

			ring.Size = UDim2.fromOffset(BTN * (1 + p * 0.75), BTN * (1 + p * 0.75))
			ringStroke.Color = col
			ringStroke.Transparency = 0.15 + p * 0.85
		else
			ringStroke.Transparency = 1
		end

		-- shake while the energy is falling
		if not holding and not done and ed > 0.02 then
			bar.Position = UDim2.new(0.5, math.sin(t * 70) * 2, 0, BAR_Y)
		else
			bar.Position = UDim2.new(0.5, 0, 0, BAR_Y)
		end

		-- sparks flying out of the energy tip
		if holding and not done then
			sparkAcc += dt * 28

			while sparkAcc >= 1 do
				sparkAcc -= 1
				spawnSpark(30 + math.clamp(ed, 0, 1) * BAR_W, BAR_Y + BAR_H / 2, col, false)
			end
		end

		-- texts
		if not done then
			if holding then
				button.Text = "HOLD..."
				status.Text = string.format("%.1fs left  -  keep holding!", math.max(0, (1 - e) * HOLD_SECONDS))
				status.TextColor3 = col
			elseif e > 0.001 then
				button.Text = "HOLD!"
				status.Text = "Energy is dropping  -  hold again!"
				status.TextColor3 = Color3.fromRGB(255, 110, 100)
			else
				button.Text = "HOLD"
				status.Text = "Press and hold for " .. HOLD_SECONDS .. " seconds"
				status.TextColor3 = MUTED
			end
		end
	end)

	-- when the saved stamp loads late (LocalStorageService), skip the check
	pcall(function()
		game:GetService("LocalStorageService"):WhenLoaded(function()
			if not done and not closing and isValid() then
				done = true
				finish(false)
			end
		end)
	end)
end

if not pcall(FX.gate) then
	-- never lock the user out if the check itself fails
	FX.gateActive = false

	pcall(function()
		local old = PlayerGui:FindFirstChild("XEVRION_VERIFY")

		if old then
			old:Destroy()
		end
	end)

	setMenuOpen(true, true)
end
