import dynamic from 'next/dynamic'
import { useRouter } from 'next/router'
import AuthGuard from 'src/shared/auth/AuthGuard.js'

const Header = dynamic(
	() => import('src/shared/header/Header.res.mjs').then((m) => m.make),
	{ ssr: false },
)

const TaskSubmissions = dynamic(
	() =>
		import('src/pages/public/TaskSubmissions.res.mjs').then((m) => m.make),
	{ ssr: false },
)

export default function Page() {
	const router = useRouter()
	const id = typeof router.query.id === 'string' ? router.query.id : ''
	return (
		<div className="appShell">
			<AuthGuard />
			<Header />
			<div className="appContent">
				<TaskSubmissions taskId={id} />
			</div>
		</div>
	)
}
