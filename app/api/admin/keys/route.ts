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

// Generate secure license key in XXXXX-XXXXX-XXXXX-XXXXX format
function generateLicenseKey(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Removed confusing chars (0,O,1,I)
  const segments: string[] = []
  
  for (let s = 0; s < 4; s++) {
    let segment = ""
    const bytes = randomBytes(5)
    for (let i = 0; i < 5; i++) {
      segment += chars[bytes[i] % chars.length]
    }
    segments.push(segment)
  }
  
  // Add checksum character
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
    const { name, duration_days } = await request.json()

    if (!name) {
      return NextResponse.json({ error: "Name is required" }, { status: 400 })
    }

    const key = generateLicenseKey()

    const supabase = await createClient()
    const { data, error } = await supabase
      .from("api_keys")
      .insert({ 
        key, 
        name,
        duration_days: duration_days || null
      })
      .select()
      .single()

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ key: data })
  } catch {
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

export async function PATCH(request: Request) {
  const admin = await verifyAdmin()
  if (!admin) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
  }

  try {
    const { id, is_active } = await request.json()

    const supabase = await createClient()
    const { error } = await supabase
      .from("api_keys")
      .update({ is_active })
      .eq("id", id)

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch {
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

export async function DELETE(request: Request) {
  const admin = await verifyAdmin()
  if (!admin) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
  }

  try {
    const { searchParams } = new URL(request.url)
    const id = searchParams.get("id")

    if (!id) {
      return NextResponse.json({ error: "ID is required" }, { status: 400 })
    }

    const supabase = await createClient()
    const { error } = await supabase.from("api_keys").delete().eq("id", id)

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch {
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
