let apiUrl: string = %raw(`process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080"`)
let authApiBase = apiUrl ++ "/auth"
