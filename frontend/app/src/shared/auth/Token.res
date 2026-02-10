@module("./token.js") @return(nullable) external getToken: unit => option<string> = "getToken"
@module("./token.js") external setToken: string => unit = "setToken"
@module("./token.js") external clearToken: unit => unit = "clearToken"
