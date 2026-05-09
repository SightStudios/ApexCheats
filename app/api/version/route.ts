import { NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"

export async function GET(request: Request) {
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

    // Get filename from query
    const { searchParams } = new URL(request.url)
    const filename = searchParams.get("filename")

    if (!filename) {
      return NextResponse.json(
        { error: "Filename is required" },
        { status: 400 }
      )
    }

    // Get latest version of file
    const { data: file, error } = await supabase
      .from("files")
      .select("*")
      .eq("filename", filename)
      .eq("is_latest", true)
      .single()

    if (error || !file) {
      return NextResponse.json(
        { error: "File not found" },
        { status: 404 }
      )
    }

    return NextResponse.json({
      filename: file.filename,
      version: file.version,
      uploaded_at: file.uploaded_at,
    })
  } catch {
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    )
  }
}
