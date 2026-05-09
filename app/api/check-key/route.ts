import { NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"

export async function POST(request: Request) {
  try {
    const body = await request.json()
    const { key, hwid } = body

    if (!key) {
      return NextResponse.json(
        { valid: false, error: "License key required" },
        { status: 401 }
      )
    }

    const supabase = await createClient()

    const { data: license, error } = await supabase
      .from("api_keys")
      .select("*")
      .eq("key", key)
      .single()

    if (error || !license) {
      return NextResponse.json(
        { valid: false, error: "Invalid license key" },
        { status: 401 }
      )
    }

    if (!license.is_active) {
      return NextResponse.json(
        { valid: false, error: "License is disabled" },
        { status: 403 }
      )
    }

    // Check HWID binding
    if (license.hwid && hwid && license.hwid !== hwid) {
      return NextResponse.json(
        { valid: false, error: "License bound to different hardware" },
        { status: 403 }
      )
    }

    // Handle first-time redemption
    if (!license.redeemed_at && license.duration_days) {
      const redeemed_at = new Date()
      const expires_at = new Date(redeemed_at)
      expires_at.setDate(expires_at.getDate() + license.duration_days)

      await supabase
        .from("api_keys")
        .update({
          redeemed_at: redeemed_at.toISOString(),
          expires_at: expires_at.toISOString(),
          hwid: hwid || null,
          last_used_at: redeemed_at.toISOString()
        })
        .eq("id", license.id)

      return NextResponse.json({
        valid: true,
        name: license.name,
        redeemed: true,
        expires_at: expires_at.toISOString(),
        days_remaining: license.duration_days
      })
    }

    // Check expiration for already redeemed licenses
    if (license.expires_at && new Date(license.expires_at) < new Date()) {
      return NextResponse.json(
        { valid: false, error: "License has expired" },
        { status: 403 }
      )
    }

    // Update last used and optionally bind HWID
    const updates: Record<string, string | null> = {
      last_used_at: new Date().toISOString()
    }
    
    if (!license.hwid && hwid) {
      updates.hwid = hwid
    }

    await supabase
      .from("api_keys")
      .update(updates)
      .eq("id", license.id)

    // Calculate days remaining
    let days_remaining = null
    if (license.expires_at) {
      const diff = new Date(license.expires_at).getTime() - Date.now()
      days_remaining = Math.ceil(diff / (1000 * 60 * 60 * 24))
    }

    return NextResponse.json({
      valid: true,
      name: license.name,
      redeemed: !!license.redeemed_at,
      expires_at: license.expires_at,
      days_remaining
    })
  } catch {
    return NextResponse.json(
      { valid: false, error: "Internal server error" },
      { status: 500 }
    )
  }
}

// Also support GET for simpler checks
export async function GET(request: Request) {
  const apiKey = request.headers.get("X-API-Key")

  if (!apiKey) {
    return NextResponse.json(
      { valid: false, error: "License key required" },
      { status: 401 }
    )
  }

  const supabase = await createClient()

  const { data: license, error } = await supabase
    .from("api_keys")
    .select("*")
    .eq("key", apiKey)
    .single()

  if (error || !license) {
    return NextResponse.json(
      { valid: false, error: "Invalid license key" },
      { status: 401 }
    )
  }

  if (!license.is_active) {
    return NextResponse.json(
      { valid: false, error: "License is disabled" },
      { status: 403 }
    )
  }

  if (license.expires_at && new Date(license.expires_at) < new Date()) {
    return NextResponse.json(
      { valid: false, error: "License has expired" },
      { status: 403 }
    )
  }

  // Update last_used_at
  await supabase
    .from("api_keys")
    .update({ last_used_at: new Date().toISOString() })
    .eq("id", license.id)

  let days_remaining = null
  if (license.expires_at) {
    const diff = new Date(license.expires_at).getTime() - Date.now()
    days_remaining = Math.ceil(diff / (1000 * 60 * 60 * 24))
  }

  return NextResponse.json({
    valid: true,
    name: license.name,
    redeemed: !!license.redeemed_at,
    expires_at: license.expires_at,
    days_remaining
  })
}
