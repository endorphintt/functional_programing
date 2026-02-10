import dynamic from "next/dynamic"
import { useRouter } from "next/router"
import AuthGuard from "src/shared/auth/AuthGuard.js"

const Header = dynamic(
  () => import("src/shared/header/Header.res.mjs").then((m) => m.make),
  { ssr: false }
)

const Task = dynamic(
  () => import("src/pages/public/Task.res.mjs").then((m) => m.make),
  { ssr: false }
)

export default function Page() {
  const router = useRouter()
  const id = typeof router.query.id === "string" ? router.query.id : ""
  return (
    <>
      <AuthGuard />
      <Header />
      <Task taskId={id} />
    </>
  )
}
