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

    // Get filename and optional version from query
    const { searchParams } = new URL(request.url)
    const filename = searchParams.get("filename")
    const version = searchParams.get("version")

    if (!filename) {
      return NextResponse.json(
        { error: "Filename is required" },
        { status: 400 }
      )
    }

    // Get file
    let fileQuery = supabase.from("files").select("*").eq("filename", filename)

    if (version) {
      fileQuery = fileQuery.eq("version", version)
    } else {
      fileQuery = fileQuery.eq("is_latest", true)
    }

    const { data: file, error } = await fileQuery.single()

    if (error || !file) {
      return NextResponse.json(
        { error: "File not found" },
        { status: 404 }
      )
    }

    // Redirect to file URL
    return NextResponse.redirect(file.file_url)
  } catch {
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    )
  }
}
