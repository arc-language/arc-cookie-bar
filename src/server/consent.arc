@route POST "/arc-cookie-bar/api/consent" -> Response
  if !globalThis._arcCookieBarReady
    globalThis._arcCookieBarReady = true
    try
      db.run("CREATE TABLE IF NOT EXISTS arc_cookie_consents (id INTEGER PRIMARY KEY AUTOINCREMENT, necessary INTEGER NOT NULL DEFAULT 1, analytics INTEGER NOT NULL DEFAULT 0, marketing INTEGER NOT NULL DEFAULT 0, preferences INTEGER NOT NULL DEFAULT 0, ip TEXT, ua TEXT, created_at TEXT DEFAULT (datetime('now')))", [])
      db.run("CREATE INDEX IF NOT EXISTS idx_arc_cconsents_created_at ON arc_cookie_consents(created_at)", [])
      db.run("CREATE INDEX IF NOT EXISTS idx_arc_cconsents_ip ON arc_cookie_consents(ip)", [])
    catch ddlErr
      globalThis._arcCookieBarReady = false
      return json({ ok: false, error: "DB unavailable" }, 500)

  if !body return json({ ok: false, error: "Invalid request" }, 400)

  const origin = request.headers.get("origin") || ""
  const host = request.headers.get("host") || ""
  if !host return json({ ok: false, error: "Forbidden" }, 403)
  const normOriginHost = origin ? origin.replace(/^https?:\/\//, "").replace(/:(?:80|443)$/, "") : ""
  const normHost = host.replace(/:(?:80|443)$/, "")
  if origin && normOriginHost != normHost
    return json({ ok: false, error: "Forbidden" }, 403)

  const fwd = request.headers.get("x-forwarded-for") || ""
  const rawIp = String(fwd).split(",")[0].trim().slice(0, 45)
  const isIpv6 = rawIp.includes(":")
  const ip6 = rawIp.indexOf("::") >= 0 ? rawIp.split("::")[0] + "::" : rawIp.split(":").slice(0, 4).join(":") + "::"
  const ip4 = rawIp.split(".").slice(0, 3).join(".") + ".0"
  const ip = rawIp ? (isIpv6 ? ip6 : ip4) : null
  const ua = (typeof body.ua === "string" ? body.ua : "").replace(/[\x00-\x1f\x7f]/g, "").slice(0, 512)
  const analytics = body.analytics ? 1 : 0
  const marketing = body.marketing ? 1 : 0
  const preferences = body.preferences ? 1 : 0

  try
    db.run("INSERT INTO arc_cookie_consents (necessary, analytics, marketing, preferences, ip, ua) VALUES (?, ?, ?, ?, ?, ?)", [1, analytics, marketing, preferences, ip, ua])
  catch e
    return json({ ok: false, error: "DB error" }, 500)

  json({ ok: true })
