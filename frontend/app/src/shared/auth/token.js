export const getToken = () => {
  if (typeof window === "undefined") return null
  return window.localStorage.getItem("access_token")
}

export const setToken = (token) => {
  if (typeof window === "undefined") return
  window.localStorage.setItem("access_token", token)
  window.dispatchEvent(new Event("auth-changed"))
}

export const clearToken = () => {
  if (typeof window === "undefined") return
  window.localStorage.removeItem("access_token")
  window.dispatchEvent(new Event("auth-changed"))
}
