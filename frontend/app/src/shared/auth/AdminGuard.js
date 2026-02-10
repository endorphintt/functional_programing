import { useEffect } from "react"
import { useRouter } from "next/router"
import { getToken, clearToken } from "./token.js"
import { isAdmin } from "./jwt.js"

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080"

export default function AdminGuard() {
  const router = useRouter()

  useEffect(() => {
    const run = async () => {
      const token = getToken()
      if (!token) {
        router.replace("/auth")
        return
      }

      if (!isAdmin()) {
        router.replace("/")
        return
      }

      try {
        const res = await fetch(`${API_URL}/auth/me`, {
          method: "GET",
          headers: { Authorization: `Bearer ${token}` },
        })
        if (!res.ok) throw new Error("bad token")
      } catch {
        clearToken()
        router.replace("/auth")
      }
    }

    run()
  }, [router])

  return null
}
