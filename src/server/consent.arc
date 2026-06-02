@route POST "/arc-cookie-bar/api/consent" -> Response
  if !globalThis._arcCBTableReady
    db.run("CREATE TABLE IF NOT EXISTS arc_cookie_consents (id INTEGER PRIMARY KEY AUTOINCREMENT, necessary INTEGER NOT NULL DEFAULT 1, analytics INTEGER NOT NULL DEFAULT 0, marketing INTEGER NOT NULL DEFAULT 0, preferences INTEGER NOT NULL DEFAULT 0, ip TEXT, ua TEXT, created_at TEXT DEFAULT (datetime('now')))", [])
    globalThis._arcCBTableReady = true

  const rawIp = String(request.headers.get("x-forwarded-for") ?? request.headers.get("cf-connecting-ip") ?? request.headers.get("x-real-ip") ?? "").split(",")[0].trim().slice(0, 45)

  const ip = rawIp.includes(":") ?
    rawIp.split(":").slice(0, 4).join(":") + "::" :
    rawIp.split(".").slice(0, 3).join(".") + ".0"

  db.run("INSERT INTO arc_cookie_consents (necessary, analytics, marketing, preferences, ip, ua) VALUES (?, ?, ?, ?, ?, ?)", [
    1,
    body.analytics ? 1 : 0,
    body.marketing ? 1 : 0,
    body.preferences ? 1 : 0,
    ip,
    String(body.ua ?? "").slice(0, 512)
  ])

  json({ ok: true })
