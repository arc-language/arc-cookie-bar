@route POST "/arc-cookie-bar/api/consent" -> Response
  db.run("CREATE TABLE IF NOT EXISTS arc_cookie_consents (id INTEGER PRIMARY KEY AUTOINCREMENT, necessary INTEGER NOT NULL DEFAULT 1, analytics INTEGER NOT NULL DEFAULT 0, marketing INTEGER NOT NULL DEFAULT 0, preferences INTEGER NOT NULL DEFAULT 0, ip TEXT, ua TEXT, created_at TEXT DEFAULT (datetime('now')))", [])

  const fwd = request.headers.get("x-forwarded-for") || ""
  const rawIp = String(fwd).split(",")[0].trim().slice(0, 45)
  const isIpv6 = rawIp.includes(":")
  const ip6 = rawIp.split(":").slice(0, 4).join(":") + "::"
  const ip4 = rawIp.split(".").slice(0, 3).join(".") + ".0"
  const ip = isIpv6 ? ip6 : ip4
  const ua = String(body.ua || "").slice(0, 512)
  const an = body.analytics ? 1 : 0
  const mk = body.marketing ? 1 : 0
  const pf = body.preferences ? 1 : 0

  db.run("INSERT INTO arc_cookie_consents (necessary, analytics, marketing, preferences, ip, ua) VALUES (?, ?, ?, ?, ?, ?)", [1, an, mk, pf, ip, ua])

  json({ ok: true })
