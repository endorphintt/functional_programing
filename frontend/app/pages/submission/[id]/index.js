import dynamic from "next/dynamic"
import { useRouter } from "next/router"
import AuthGuard from "src/shared/auth/AuthGuard.js"

const Header = dynamic(
  () => import("src/shared/header/Header.res.mjs").then((m) => m.make),
  { ssr: false }
)

const Submission = dynamic(
  () => import("src/pages/public/Submission.res.mjs").then((m) => m.make),
  { ssr: false }
)

export default function Page() {
  const router = useRouter()
  const id = typeof router.query.id === "string" ? router.query.id : ""
  return (
    <div className="appShell">
      <AuthGuard />
      <Header />
      <div className="appContent">
        <Submission submissionId={id} />
      </div>
    </div>
  )
}
