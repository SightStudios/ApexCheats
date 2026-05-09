import { cookies } from "next/headers"
import { redirect } from "next/navigation"
import { createClient } from "@/lib/supabase/server"
import { AdminDashboard } from "@/components/admin-dashboard"

export default async function AdminPage() {
  const cookieStore = await cookies()
  const adminSession = cookieStore.get("admin_session")

  if (!adminSession) {
    redirect("/admin/login")
  }

  const supabase = await createClient()

  // Verify admin exists
  const { data: admin } = await supabase
    .from("admins")
    .select("*")
    .eq("id", adminSession.value)
    .single()

  if (!admin) {
    redirect("/admin/login")
  }

  // Fetch initial data
  const { data: apiKeys } = await supabase
    .from("api_keys")
    .select("*")
    .order("created_at", { ascending: false })

  const { data: files } = await supabase
    .from("files")
    .select("*")
    .order("uploaded_at", { ascending: false })

  return (
    <AdminDashboard
      adminUsername={admin.username}
      initialApiKeys={apiKeys || []}
      initialFiles={files || []}
    />
  )
}
