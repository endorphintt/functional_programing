type me = {
  id: string,
  email: string,
  nickname: string,
  role: string,
  rating: int,
}

type leaderboardItem = {
  id: string,
  email: string,
  nickname: string,
  rating: int,
}

type leaderboard = {
  limit: int,
  offset: int,
  items: array<leaderboardItem>,
}
