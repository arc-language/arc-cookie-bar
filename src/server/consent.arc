@server fn anonymizeIp(rawIp: String) -> Any
  if !rawIp return null
  const isIpv6 = rawIp.includes(":")
  if isIpv6
    const ip6parts = rawIp.split("::")
    const ip6left = ip6parts[0] ? ip6parts[0].split(":") : []
    const ip6right = ip6parts.length > 1 && ip6parts[1] ? ip6parts[1].split(":") : []
    const ip6PadCount = 8 - ip6left.length - ip6right.length
    const ip6Expanded = ip6left.concat(Array(ip6PadCount > 0 ? ip6PadCount : 0).fill("0")).concat(ip6right)
    return ip6Expanded.slice(0, 4).join(":") + "::"
  return rawIp.split(".").slice(0, 3).join(".") + ".0"

@server fn checkOrigin(origin: String, host: String) -> Any
  if !host return false
  if !origin return true
  const normalizedOriginHost = origin.replace(/^https?:\/\//, "").replace(/:(?:80|443)$/, "")
  const normalizedHost = host.replace(/:(?:80|443)$/, "")
  return normalizedOriginHost == normalizedHost

@route POST "/arc-cookie-bar/api/consent" -> Response
  # DDL runs once per process; flag is set only after success so concurrent cold-start requests each retry safely
  if !globalThis._arcCookieBarReady
    try
      db.run("CREATE TABLE IF NOT EXISTS arc_cookie_consents (id INTEGER PRIMARY KEY AUTOINCREMENT, necessary INTEGER NOT NULL DEFAULT 1, analytics INTEGER NOT NULL DEFAULT 0, marketing INTEGER NOT NULL DEFAULT 0, preferences INTEGER NOT NULL DEFAULT 0, ip TEXT, ua TEXT, created_at TEXT DEFAULT (datetime('now')))", [])
      db.run("CREATE INDEX IF NOT EXISTS idx_arc_cconsents_created_at ON arc_cookie_consents(created_at)", [])
      db.run("CREATE INDEX IF NOT EXISTS idx_arc_cconsents_ip ON arc_cookie_consents(ip)", [])
      globalThis._arcCookieBarReady = true
    catch e
      console.error("[arc-cookie-bar] DDL failed:", e)
      return json({ ok: false, error: "DB unavailable" }, 500)

  if !body return json({ ok: false, error: "Invalid request" }, 400)

  const origin = request.headers.get("origin") || ""
  const host = request.headers.get("host") || ""
  if !checkOrigin(origin, host)
    return json({ ok: false, error: "Forbidden" }, 403)

  const fwd = request.headers.get("x-forwarded-for") || ""
  const rawIp = String(fwd).split(",")[0].trim().slice(0, 45)
  const ip = anonymizeIp(rawIp)
  const ua = (typeof body.ua === "string" ? body.ua : "").replace(/[\x00-\x1f\x7f]/g, "").slice(0, 512)
  const analytics = body.analytics ? 1 : 0
  const marketing = body.marketing ? 1 : 0
  const preferences = body.preferences ? 1 : 0

  try
    db.run("INSERT INTO arc_cookie_consents (necessary, analytics, marketing, preferences, ip, ua) VALUES (?, ?, ?, ?, ?, ?)", [1, analytics, marketing, preferences, ip, ua])
  catch e
    console.error("[arc-cookie-bar] insert failed:", e)
    return json({ ok: false, error: "DB error" }, 500)

  json({ ok: true })
