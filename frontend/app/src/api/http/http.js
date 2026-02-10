const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080"

function isAbsolute(url) {
  return /^https?:\/\//i.test(url)
}

function fullUrl(url) {
  if (isAbsolute(url)) return url
  const u = url.startsWith("/") ? url : "/" + url
  return API_URL + u
}

function getAuthHeader(opts) {
  if (typeof window === "undefined") return {}
  const token = (opts && opts.authToken) || localStorage.getItem("access_token")
  if (!token) return {}
  return { Authorization: `Bearer ${token}` }
}

async function request(url, method, options = {}) {
  const { headers = {}, body, withCredentials = false, skipAuth = false, authToken, ...rest } = options
  const isFormData = typeof FormData !== "undefined" && body instanceof FormData

  const res = await fetch(fullUrl(url), {
    method,
    headers: {
      ...(isFormData ? {} : { "Content-Type": "application/json", Accept: "application/json" }),
      ...(skipAuth ? {} : getAuthHeader({ authToken })),
      ...headers,
    },
    body: body !== undefined ? (isFormData ? body : JSON.stringify(body)) : undefined,
    credentials: withCredentials ? "include" : "same-origin",
    ...rest,
  })

  const parseJson = async () => {
    try {
      return await res.json()
    } catch {
      return null
    }
  }

  if (!res.ok) {
    const data = await parseJson()
    const message =
      data && typeof data === "object" && "message" in data && data.message
        ? data.message
        : `HTTP ${res.status}`
    const error = new Error(String(message))
    error.status = res.status
    error.data = data
    throw error
  }

  if (res.status === 204) return undefined
  return await parseJson()
}

export function getJson(url, options) {
  return request(url, "GET", options)
}

export function postJson(url, body, options) {
  return request(url, "POST", { ...options, body })
}

export function putJson(url, body, options) {
  return request(url, "PUT", { ...options, body })
}

export function patchJson(url, body, options) {
  return request(url, "PATCH", { ...options, body })
}

export function deleteJson(url, options) {
  return request(url, "DELETE", options)
}
