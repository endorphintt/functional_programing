type loginRequest = {
  email: string,
  password: string,
}

type registerRequest = {
  email: string,
  password: string,
  nickname: string,
}

type authResponse = {
  token: string,
}

type me = {
  id: string,
  role: string,
  email: string,
  nickname: string,
  rating: int,
}
