import { NextResponse } from "next/server"
import { cookies } from "next/headers"
import { createClient } from "@/lib/supabase/server"

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

export async function POST(request: Request) {
  const admin = await verifyAdmin()
  if (!admin) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
  }

  try {
    const { filename, version, file_url, file_size } = await request.json()

    if (!filename || !version || !file_url) {
      return NextResponse.json(
        { error: "Filename, version, and file_url are required" },
        { status: 400 }
      )
    }

    const supabase = await createClient()

    // Mark existing versions of this file as not latest
    await supabase
      .from("files")
      .update({ is_latest: false })
      .eq("filename", filename)

    // Insert new file
    const { data, error } = await supabase
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

    return NextResponse.json({ file: data })
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
    const { error } = await supabase.from("files").delete().eq("id", id)

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch {
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
