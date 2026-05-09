import { NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"

export async function POST(request: Request) {
  const apiKey = request.headers.get("X-API-Key")

  if (!apiKey) {
    return NextResponse.json(
      { error: "API key required" },
      { status: 401 }
    )
  }

  try {
    const supabase = await createClient()

    // Verify API key
    const { data: key, error: keyError } = await supabase
      .from("api_keys")
      .select("*")
      .eq("key", apiKey)
      .eq("is_active", true)
      .single()

    if (keyError || !key) {
      return NextResponse.json(
        { error: "Invalid or inactive API key" },
        { status: 401 }
      )
    }

    // Update last_used_at
    await supabase
      .from("api_keys")
      .update({ last_used_at: new Date().toISOString() })
      .eq("id", key.id)

    // Get file data from request
    const { filename, version, file_url, file_size } = await request.json()

    if (!filename || !version || !file_url) {
      return NextResponse.json(
        { error: "Filename, version, and file_url are required" },
        { status: 400 }
      )
    }

    // Mark existing versions as not latest
    await supabase
      .from("files")
      .update({ is_latest: false })
      .eq("filename", filename)

    // Insert new file
    const { data: file, error } = await supabase
      .from("files")
      .insert({
        filename,
        version,
        file_url,
        file_size: file_size || null,
        is_latest: true,
      })
      .select()
      .single()

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({
      success: true,
      file: {
        id: file.id,
        filename: file.filename,
        version: file.version,
        uploaded_at: file.uploaded_at,
      },
    })
  } catch {
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    )
  }
}
