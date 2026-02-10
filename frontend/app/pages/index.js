import dynamic from "next/dynamic"
import AuthGuard from "src/shared/auth/AuthGuard.js"

const Header = dynamic(
  () => import("src/shared/header/Header.res.mjs").then((m) => m.make),
  { ssr: false }
)

const Home = dynamic(
  () => import("src/pages/public/Home.res.mjs").then((m) => m.make),
  { ssr: false }
)

export default function Page() {
  return (
    <div className="appShell">
      <AuthGuard />
      <Header />
      <div className="appContent">
        <Home />
      </div>
    </div>
  )
}
