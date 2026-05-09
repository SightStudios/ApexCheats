import Link from "next/link"
import { Shield, Lock, Zap, Server } from "lucide-react"

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col relative overflow-hidden">
      {/* Background Effects */}
      <div className="fixed inset-0 -z-10">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-primary/10 via-background to-background" />
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-primary/5 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-primary/5 rounded-full blur-3xl" />
        {/* Grid pattern */}
        <div 
          className="absolute inset-0 opacity-[0.02]"
          style={{
            backgroundImage: `linear-gradient(to right, currentColor 1px, transparent 1px),
                              linear-gradient(to bottom, currentColor 1px, transparent 1px)`,
            backgroundSize: '60px 60px'
          }}
        />
      </div>

      {/* Header */}
      <header className="border-b border-border/50 bg-card/50 backdrop-blur-sm">
        <div className="max-w-5xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Shield className="h-6 w-6 text-primary" />
            <span className="text-xl font-semibold text-foreground tracking-tight">Apex</span>
          </div>
          <Link
            href="/admin/login"
            className="text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            Admin
          </Link>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 flex items-center justify-center px-6 py-16">
        <div className="max-w-2xl w-full text-center">
          <div className="mb-12">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-border/50 bg-card/50 text-sm text-muted-foreground mb-6">
              <Lock className="h-3.5 w-3.5" />
              Secure License Management
            </div>
            <h1 className="text-4xl font-bold text-foreground mb-4 tracking-tight text-balance">
              License Authentication System
            </h1>
            <p className="text-lg text-muted-foreground leading-relaxed max-w-lg mx-auto text-pretty">
              Secure key validation, hardware binding, and file distribution for your applications.
            </p>
          </div>

          {/* Feature Grid */}
          <div className="grid gap-4 sm:grid-cols-3 mb-12">
            <FeatureCard
              icon={<Lock className="h-5 w-5" />}
              title="Secure Keys"
              description="Cryptographically secure license generation"
            />
            <FeatureCard
              icon={<Zap className="h-5 w-5" />}
              title="Fast Validation"
              description="Real-time license verification"
            />
            <FeatureCard
              icon={<Server className="h-5 w-5" />}
              title="HWID Binding"
              description="Hardware-bound license protection"
            />
          </div>

          {/* Status Indicator */}
          <div className="inline-flex items-center gap-2 text-sm text-muted-foreground">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
            </span>
            System Operational
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-border/50 bg-card/30 py-4">
        <div className="max-w-5xl mx-auto px-6 text-center text-sm text-muted-foreground">
          Apex License System
        </div>
      </footer>
    </div>
  )
}

function FeatureCard({
  icon,
  title,
  description,
}: {
  icon: React.ReactNode
  title: string
  description: string
}) {
  return (
    <div className="bg-card/50 border border-border/50 rounded-lg p-4 backdrop-blur-sm">
      <div className="text-primary mb-2">{icon}</div>
      <h3 className="text-sm font-medium text-foreground mb-1">{title}</h3>
      <p className="text-xs text-muted-foreground">{description}</p>
    </div>
  )
}
