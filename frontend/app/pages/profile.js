import dynamic from "next/dynamic"
import AuthGuard from "src/shared/auth/AuthGuard.js"

const Header = dynamic(
  () => import("src/shared/header/Header.res.mjs").then((m) => m.make),
  { ssr: false }
)

const Profile = dynamic(
  () => import("src/pages/user/Profile.res.mjs").then((m) => m.make),
  { ssr: false }
)

export default function Page() {
  return (
    <div className="appShell">
      <AuthGuard />
      <Header />
      <div className="appContent">
        <Profile />
      </div>
    </div>
  )
}
