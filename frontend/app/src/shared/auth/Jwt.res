@module("./jwt.js") @return(nullable) external getRole: unit => option<string> = "getRole"
@module("./jwt.js") external isAdmin: unit => bool = "isAdmin"
