import { create } from "zustand"
import { persist } from "zustand/middleware"

export const useThemeStore = create(
  persist(
    (set, get) => ({
      theme: "white",
      setTheme: (theme) => set({ theme }),
      toggleTheme: () => set({ theme: get().theme === "white" ? "black" : "white" }),
    }),
    { name: "theme" }
  )
)
