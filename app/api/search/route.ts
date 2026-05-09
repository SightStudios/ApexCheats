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

    // Get search query
    const { searchParams } = new URL(request.url)
    const query = searchParams.get("q") || ""

    // Search files
    let filesQuery = supabase.from("files").select("*")

    if (query) {
      filesQuery = filesQuery.ilike("filename", `%${query}%`)
    }

    const { data: files, error } = await filesQuery.order("uploaded_at", {
      ascending: false,
    })

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ files })
  } catch {
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    )
  }
}
