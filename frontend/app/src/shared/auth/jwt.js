import { getToken } from "./token.js"

const decodeBase64Url = (s) => {
  const pad = "=".repeat((4 - (s.length % 4)) % 4)
  const b64 = (s + pad).replace(/-/g, "+").replace(/_/g, "/")
  try {
    return atob(b64)
  } catch {
    return null
  }
}

export const getRole = () => {
  if (typeof window === "undefined") return null
  const token = getToken()
  if (!token) return null
  const parts = token.split(".")
  if (parts.length !== 3) return null
  const json = decodeBase64Url(parts[1])
  if (!json) return null
  try {
    const payload = JSON.parse(json)
    return typeof payload.role === "string" ? payload.role : null
  } catch {
    return null
  }
}

export const isAdmin = () => getRole() === "admin"
