"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import {
  Shield,
  Key,
  FileText,
  Plus,
  Trash2,
  Copy,
  Check,
  LogOut,
  RefreshCw,
  Clock,
  Layers,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"

interface ApiKey {
  id: string
  key: string
  name: string
  is_active: boolean
  created_at: string
  last_used_at: string | null
  expires_at: string | null
  duration_days: number | null
  redeemed_at: string | null
  hwid: string | null
}

interface File {
  id: string
  filename: string
  version: string
  file_url: string
  file_size: number | null
  uploaded_at: string
  is_latest: boolean
}

export function AdminDashboard({
  adminUsername,
  initialApiKeys,
  initialFiles,
}: {
  adminUsername: string
  initialApiKeys: ApiKey[]
  initialFiles: File[]
}) {
  const router = useRouter()
  const [activeTab, setActiveTab] = useState<"keys" | "files">("keys")
  const [apiKeys, setApiKeys] = useState<ApiKey[]>(initialApiKeys)
  const [files, setFiles] = useState<File[]>(initialFiles)
  const [copiedId, setCopiedId] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  
  // Single key form
  const [newKeyName, setNewKeyName] = useState("")
  const [newKeyDuration, setNewKeyDuration] = useState("30")
  
  // Bulk add form
  const [showBulkAdd, setShowBulkAdd] = useState(false)
  const [bulkPrefix, setBulkPrefix] = useState("")
  const [bulkCount, setBulkCount] = useState("10")
  const [bulkDuration, setBulkDuration] = useState("30")

  async function handleLogout() {
    await fetch("/api/admin/logout", { method: "POST" })
    router.push("/admin/login")
  }

  async function generateKey() {
    if (!newKeyName.trim()) return
    setLoading(true)

    try {
      const res = await fetch("/api/admin/keys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ 
          name: newKeyName,
          duration_days: parseInt(newKeyDuration) || null
        }),
      })

      if (res.ok) {
        const data = await res.json()
        setApiKeys([data.key, ...apiKeys])
        setNewKeyName("")
      }
    } finally {
      setLoading(false)
    }
  }

  async function bulkGenerateKeys() {
    if (!bulkPrefix.trim() || !bulkCount) return
    setLoading(true)

    try {
      const res = await fetch("/api/admin/keys/bulk", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ 
          prefix: bulkPrefix,
          count: parseInt(bulkCount),
          duration_days: parseInt(bulkDuration) || null
        }),
      })

      if (res.ok) {
        const data = await res.json()
        setApiKeys([...data.keys, ...apiKeys])
        setBulkPrefix("")
        setBulkCount("10")
        setShowBulkAdd(false)
      }
    } finally {
      setLoading(false)
    }
  }

  async function deleteKey(id: string) {
    const res = await fetch(`/api/admin/keys?id=${id}`, { method: "DELETE" })
    if (res.ok) {
      setApiKeys(apiKeys.filter((k) => k.id !== id))
    }
  }

  async function toggleKeyStatus(id: string, currentStatus: boolean) {
    const res = await fetch("/api/admin/keys", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id, is_active: !currentStatus }),
    })

    if (res.ok) {
      setApiKeys(
        apiKeys.map((k) =>
          k.id === id ? { ...k, is_active: !currentStatus } : k
        )
      )
    }
  }

  async function deleteFile(id: string) {
    const res = await fetch(`/api/admin/files?id=${id}`, { method: "DELETE" })
    if (res.ok) {
      setFiles(files.filter((f) => f.id !== id))
    }
  }

  function copyToClipboard(text: string, id: string) {
    navigator.clipboard.writeText(text)
    setCopiedId(id)
    setTimeout(() => setCopiedId(null), 2000)
  }

  function refreshData() {
    router.refresh()
  }

  function getKeyStatus(key: ApiKey) {
    if (!key.is_active) return { status: "disabled", color: "bg-muted text-muted-foreground" }
    if (!key.redeemed_at) return { status: "unredeemed", color: "bg-yellow-500/20 text-yellow-400" }
    if (key.expires_at && new Date(key.expires_at) < new Date()) {
      return { status: "expired", color: "bg-destructive/20 text-destructive" }
    }
    return { status: "active", color: "bg-primary/20 text-primary" }
  }

  function getTimeRemaining(key: ApiKey) {
    if (!key.redeemed_at || !key.expires_at) return null
    const now = new Date()
    const expires = new Date(key.expires_at)
    const diff = expires.getTime() - now.getTime()
    if (diff <= 0) return "Expired"
    const days = Math.floor(diff / (1000 * 60 * 60 * 24))
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    if (days > 0) return `${days}d ${hours}h left`
    return `${hours}h left`
  }

  return (
    <div className="min-h-screen relative overflow-hidden">
      {/* Background Effects */}
      <div className="fixed inset-0 -z-10">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-primary/5 via-background to-background" />
        <div className="absolute top-0 right-0 w-96 h-96 bg-primary/5 rounded-full blur-3xl" />
        <div 
          className="absolute inset-0 opacity-[0.015]"
          style={{
            backgroundImage: `linear-gradient(to right, currentColor 1px, transparent 1px),
                              linear-gradient(to bottom, currentColor 1px, transparent 1px)`,
            backgroundSize: '60px 60px'
          }}
        />
      </div>

      {/* Header */}
      <header className="border-b border-border/50 bg-card/50 backdrop-blur-sm sticky top-0 z-10">
        <div className="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Shield className="h-6 w-6 text-primary" />
            <span className="text-xl font-semibold text-foreground tracking-tight">
              Apex
            </span>
            <span className="text-sm text-muted-foreground ml-2">Admin</span>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-muted-foreground">{adminUsername}</span>
            <Button variant="ghost" size="sm" onClick={handleLogout}>
              <LogOut className="h-4 w-4 mr-1.5" />
              Logout
            </Button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-6xl mx-auto px-6 py-8">
        {/* Tabs */}
        <div className="flex items-center gap-1 border-b border-border/50 mb-6">
          <button
            onClick={() => setActiveTab("keys")}
            className={`px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors ${
              activeTab === "keys"
                ? "border-primary text-foreground"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            <Key className="h-4 w-4 inline-block mr-1.5 -mt-0.5" />
            Licenses
          </button>
          <button
            onClick={() => setActiveTab("files")}
            className={`px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors ${
              activeTab === "files"
                ? "border-primary text-foreground"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            <FileText className="h-4 w-4 inline-block mr-1.5 -mt-0.5" />
            Files
          </button>
          <div className="flex-1" />
          <Button variant="ghost" size="sm" onClick={refreshData}>
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>

        {/* API Keys Tab */}
        {activeTab === "keys" && (
          <div className="space-y-6">
            {/* Generate New Key */}
            <div className="bg-card/50 border border-border/50 rounded-lg p-4 backdrop-blur-sm">
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-sm font-medium text-foreground">
                  Generate License
                </h3>
                <Button 
                  variant="ghost" 
                  size="sm"
                  onClick={() => setShowBulkAdd(!showBulkAdd)}
                >
                  <Layers className="h-4 w-4 mr-1.5" />
                  {showBulkAdd ? "Single" : "Bulk"}
                </Button>
              </div>
              
              {!showBulkAdd ? (
                <div className="flex gap-3">
                  <div className="flex-1">
                    <Label htmlFor="keyName" className="sr-only">
                      License Name
                    </Label>
                    <Input
                      id="keyName"
                      placeholder="License name"
                      value={newKeyName}
                      onChange={(e) => setNewKeyName(e.target.value)}
                      className="bg-input/50"
                    />
                  </div>
                  <div className="w-32">
                    <Label htmlFor="keyDuration" className="sr-only">
                      Duration (days)
                    </Label>
                    <div className="relative">
                      <Input
                        id="keyDuration"
                        type="number"
                        placeholder="Days"
                        value={newKeyDuration}
                        onChange={(e) => setNewKeyDuration(e.target.value)}
                        className="bg-input/50 pr-10"
                      />
                      <Clock className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    </div>
                  </div>
                  <Button onClick={generateKey} disabled={loading || !newKeyName.trim()}>
                    <Plus className="h-4 w-4 mr-1.5" />
                    Generate
                  </Button>
                </div>
              ) : (
                <div className="space-y-3">
                  <div className="flex gap-3">
                    <div className="flex-1">
                      <Label htmlFor="bulkPrefix" className="text-xs text-muted-foreground">
                        Name Prefix
                      </Label>
                      <Input
                        id="bulkPrefix"
                        placeholder="e.g. Customer"
                        value={bulkPrefix}
                        onChange={(e) => setBulkPrefix(e.target.value)}
                        className="bg-input/50 mt-1"
                      />
                    </div>
                    <div className="w-24">
                      <Label htmlFor="bulkCount" className="text-xs text-muted-foreground">
                        Count
                      </Label>
                      <Input
                        id="bulkCount"
                        type="number"
                        min="1"
                        max="100"
                        value={bulkCount}
                        onChange={(e) => setBulkCount(e.target.value)}
                        className="bg-input/50 mt-1"
                      />
                    </div>
                    <div className="w-24">
                      <Label htmlFor="bulkDuration" className="text-xs text-muted-foreground">
                        Days
                      </Label>
                      <Input
                        id="bulkDuration"
                        type="number"
                        value={bulkDuration}
                        onChange={(e) => setBulkDuration(e.target.value)}
                        className="bg-input/50 mt-1"
                      />
                    </div>
                  </div>
                  <Button 
                    onClick={bulkGenerateKeys} 
                    disabled={loading || !bulkPrefix.trim()}
                    className="w-full"
                  >
                    <Layers className="h-4 w-4 mr-1.5" />
                    Generate {bulkCount} Licenses
                  </Button>
                </div>
              )}
            </div>

            {/* Keys List */}
            <div className="bg-card/50 border border-border/50 rounded-lg overflow-hidden backdrop-blur-sm">
              <div className="px-4 py-3 bg-secondary/30 border-b border-border/50">
                <h3 className="text-sm font-medium text-foreground">
                  Licenses ({apiKeys.length})
                </h3>
              </div>
              {apiKeys.length === 0 ? (
                <div className="px-4 py-8 text-center text-muted-foreground text-sm">
                  No licenses generated yet
                </div>
              ) : (
                <div className="divide-y divide-border/50">
                  {apiKeys.map((key) => {
                    const { status, color } = getKeyStatus(key)
                    const timeRemaining = getTimeRemaining(key)
                    return (
                      <div
                        key={key.id}
                        className="px-4 py-3 flex items-center gap-4"
                      >
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className="font-medium text-foreground text-sm">
                              {key.name}
                            </span>
                            <span className={`text-xs px-1.5 py-0.5 rounded capitalize ${color}`}>
                              {status}
                            </span>
                            {key.duration_days && !key.redeemed_at && (
                              <span className="text-xs px-1.5 py-0.5 rounded bg-muted text-muted-foreground">
                                {key.duration_days}d license
                              </span>
                            )}
                            {timeRemaining && (
                              <span className="text-xs text-muted-foreground">
                                {timeRemaining}
                              </span>
                            )}
                          </div>
                          <div className="flex items-center gap-2 mt-1">
                            <code className="text-xs font-mono text-muted-foreground bg-secondary/50 px-1.5 py-0.5 rounded">
                              {key.key}
                            </code>
                            <button
                              onClick={() => copyToClipboard(key.key, key.id)}
                              className="text-muted-foreground hover:text-foreground transition-colors"
                            >
                              {copiedId === key.id ? (
                                <Check className="h-3.5 w-3.5 text-primary" />
                              ) : (
                                <Copy className="h-3.5 w-3.5" />
                              )}
                            </button>
                          </div>
                          <p className="text-xs text-muted-foreground mt-1">
                            Created {new Date(key.created_at).toLocaleDateString()}
                            {key.redeemed_at && ` | Redeemed ${new Date(key.redeemed_at).toLocaleDateString()}`}
                            {key.hwid && ` | HWID: ${key.hwid.slice(0, 8)}...`}
                          </p>
                        </div>
                        <div className="flex items-center gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => toggleKeyStatus(key.id, key.is_active)}
                            className="border-border/50"
                          >
                            {key.is_active ? "Disable" : "Enable"}
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => deleteKey(key.id)}
                            className="text-destructive hover:text-destructive border-border/50"
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}
            </div>
          </div>
        )}

        {/* Files Tab */}
        {activeTab === "files" && (
          <div className="space-y-6">
            {/* Upload New File */}
            <FileUploader
              onUpload={(file: File) => setFiles([file, ...files])}
            />

            {/* Files List */}
            <div className="bg-card/50 border border-border/50 rounded-lg overflow-hidden backdrop-blur-sm">
              <div className="px-4 py-3 bg-secondary/30 border-b border-border/50">
                <h3 className="text-sm font-medium text-foreground">
                  Files ({files.length})
                </h3>
              </div>
              {files.length === 0 ? (
                <div className="px-4 py-8 text-center text-muted-foreground text-sm">
                  No files uploaded yet
                </div>
              ) : (
                <div className="divide-y divide-border/50">
                  {files.map((file) => (
                    <div
                      key={file.id}
                      className="px-4 py-3 flex items-center gap-4"
                    >
                      <FileText className="h-5 w-5 text-muted-foreground" />
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-foreground text-sm truncate">
                            {file.filename}
                          </span>
                          {file.is_latest && (
                            <span className="text-xs px-1.5 py-0.5 rounded bg-primary/20 text-primary">
                              Latest
                            </span>
                          )}
                        </div>
                        <p className="text-xs text-muted-foreground mt-0.5">
                          v{file.version} |{" "}
                          {file.file_size
                            ? `${(file.file_size / 1024).toFixed(1)} KB`
                            : "Unknown size"}{" "}
                          | {new Date(file.uploaded_at).toLocaleDateString()}
                        </p>
                      </div>
                      <div className="flex items-center gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => deleteFile(file.id)}
                          className="text-destructive hover:text-destructive border-border/50"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </main>
    </div>
  )
}

function FileUploader({ onUpload }: { onUpload: (file: File) => void }) {
  const [filename, setFilename] = useState("")
  const [version, setVersion] = useState("")
  const [fileUrl, setFileUrl] = useState("")
  const [loading, setLoading] = useState(false)

  async function handleUpload() {
    if (!filename.trim() || !version.trim() || !fileUrl.trim()) return
    setLoading(true)

    try {
      const res = await fetch("/api/admin/files", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ filename, version, file_url: fileUrl }),
      })

      if (res.ok) {
        const data = await res.json()
        onUpload(data.file)
        setFilename("")
        setVersion("")
        setFileUrl("")
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="bg-card/50 border border-border/50 rounded-lg p-4 backdrop-blur-sm">
      <h3 className="text-sm font-medium text-foreground mb-3">
        Add New File
      </h3>
      <div className="grid gap-3 sm:grid-cols-3">
        <div>
          <Label htmlFor="filename" className="text-xs text-muted-foreground">
            Filename
          </Label>
          <Input
            id="filename"
            placeholder="app.exe"
            value={filename}
            onChange={(e) => setFilename(e.target.value)}
            className="mt-1 bg-input/50"
          />
        </div>
        <div>
          <Label htmlFor="version" className="text-xs text-muted-foreground">
            Version
          </Label>
          <Input
            id="version"
            placeholder="1.0.0"
            value={version}
            onChange={(e) => setVersion(e.target.value)}
            className="mt-1 bg-input/50"
          />
        </div>
        <div>
          <Label htmlFor="fileUrl" className="text-xs text-muted-foreground">
            File URL
          </Label>
          <Input
            id="fileUrl"
            placeholder="https://..."
            value={fileUrl}
            onChange={(e) => setFileUrl(e.target.value)}
            className="mt-1 bg-input/50"
          />
        </div>
      </div>
      <Button
        onClick={handleUpload}
        disabled={loading || !filename.trim() || !version.trim() || !fileUrl.trim()}
        className="mt-3"
      >
        <Plus className="h-4 w-4 mr-1.5" />
        Add File
      </Button>
    </div>
  )
}
