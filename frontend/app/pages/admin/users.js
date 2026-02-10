import dynamic from "next/dynamic"
import AuthGuard from "src/shared/auth/AuthGuard.js"
import AdminGuard from "src/shared/auth/AdminGuard.js"

const Header = dynamic(() => import("src/shared/header/Header.res.mjs").then((m) => m.make), { ssr: false })
const AdminUsers = dynamic(() => import("src/pages/admin/AdminUsers.res.mjs").then((m) => m.make), { ssr: false })

export default function Page() {
  return (
    <div className="appShell">
      <AuthGuard />
      <AdminGuard />
      <Header />
      <div className="appContent">
        <AdminUsers />
      </div>
    </div>
  )
}
