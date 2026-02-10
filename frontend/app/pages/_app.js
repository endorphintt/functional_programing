import "../src/styles/globals.scss"
import { make as ResApp } from "src/App.res.mjs"

export default function App({Component, pageProps}) {
  return <ResApp><Component {...pageProps} /></ResApp>
}
