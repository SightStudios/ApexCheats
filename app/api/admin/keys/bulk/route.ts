import { NextResponse } from "next/server"
import { cookies } from "next/headers"
import { createClient } from "@/lib/supabase/server"
import { randomBytes, createHash } from "crypto"

async function verifyAdmin() {
  const cookieStore = await cookies()
  const adminSession = cookieStore.get("admin_session")
  if (!adminSession) return null

  const supabase = await createClient()
  const { data: admin } = await supabase
    .from("admins")
    .select("id")
    .eq("id", adminSession.value)
    .single()

  return admin
}

// Generate secure license key in XXXXX-XXXXX-XXXXX-XXXXX-X format
function generateLicenseKey(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
  const segments: string[] = []
  
  for (let s = 0; s < 4; s++) {
    let segment = ""
    const bytes = randomBytes(5)
    for (let i = 0; i < 5; i++) {
      segment += chars[bytes[i] % chars.length]
    }
    segments.push(segment)
  }
  
  const keyWithoutCheck = segments.join("-")
  const hash = createHash("sha256").update(keyWithoutCheck).digest("hex")
  const checkChar = chars[parseInt(hash.slice(0, 2), 16) % chars.length]
  
  return `${keyWithoutCheck}-${checkChar}`
}

export async function POST(request: Request) {
  const admin = await verifyAdmin()
  if (!admin) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
  }

  try {
    const { prefix, count, duration_days } = await request.json()

    if (!prefix || !count) {
      return NextResponse.json({ error: "Prefix and count are required" }, { status: 400 })
    }

    const keyCount = Math.min(Math.max(1, count), 100) // Limit 1-100 keys
    const keysToInsert = []

    for (let i = 0; i < keyCount; i++) {
      keysToInsert.push({
        key: generateLicenseKey(),
        name: `${prefix} #${i + 1}`,
        duration_days: duration_days || null
      })
    }

    const supabase = await createClient()
    const { data, error } = await supabase
      .from("api_keys")
      .insert(keysToInsert)
      .select()

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ keys: data })
  } catch {
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
