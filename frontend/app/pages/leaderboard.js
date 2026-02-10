import dynamic from "next/dynamic"
import AuthGuard from "src/shared/auth/AuthGuard.js"

const Header = dynamic(
  () => import("src/shared/header/Header.res.mjs").then((m) => m.make),
  { ssr: false }
)

const Leaderboard = dynamic(
  () => import("src/pages/public/Leaderboard.res.mjs").then((m) => m.make),
  { ssr: false }
)

export default function Page() {
  return (
    <div className="appShell">
      <AuthGuard />
      <Header />
      <div className="appContent">
        <Leaderboard />
      </div>
    </div>
  )
}
