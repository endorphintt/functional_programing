open Lwt.Infix

let db_url =
  match Sys.getenv_opt "DATABASE_URL" with
  | Some v -> v
  | None -> "postgresql://pf_user:password@localhost/pf"

let () =
  Dream.run
  @@ Dream.logger
  @@ Cors.middleware
  @@ Dream.sql_pool db_url
  @@ Dream.router [
    Dream.get "/health" (fun _ -> Dream.json {|{"ok":true}|});

    Dream.post "/auth/register" Auth.register;
    Dream.post "/auth/login" Auth.login;
    Dream.get "/auth/me" (Auth.require_auth Auth.me_handler);

    Dream.get "/topics" Topics.list;
    Dream.get "/topics/:id/page" Topics.page;
    Dream.get "/topics/:id/paragraphs" Topic_paragraphs.list;
    Dream.get "/topics/:id/tasks" Tasks.list_by_topic;

    Dream.get "/tasks" Tasks.list;
    Dream.get "/tasks/my" (Auth.require_auth Tasks.my_tasks);
    Dream.get "/tasks/:id" Tasks.show;
    Dream.post "/tasks/:id/submit" (Auth.require_auth Tasks.submit);
    Dream.get "/tasks/:id/submissions" (Auth.require_auth Tasks.my_submissions);
    Dream.get "/tasks/:id/my-best" (Auth.require_auth Tasks.my_best);

    Dream.get "/submissions/:id" (Auth.require_auth Submissions.get_one);

    Dream.get "/users/me" (Auth.require_auth Users.me_handler);
    Dream.get "/users/leaderboard" Leaderboard.leaderboard;

    Dream.get "/admin/topics" (Auth.require_admin_auth Topics.list_admin);
    Dream.get "/admin/topics/:id/page" (Auth.require_admin_auth Topics.page_admin);
    Dream.post "/admin/topics" (Auth.require_admin_auth Topics.create);
    Dream.put "/admin/topics/:id/archive" (Auth.require_admin_auth Topics.archive);
    Dream.put "/admin/topics/:id/unarchive" (Auth.require_admin_auth Topics.unarchive);
    Dream.post "/admin/topics/:id/paragraphs" (Auth.require_admin_auth Topic_paragraphs.add);
    Dream.delete "/admin/topic-paragraphs/:id" (Auth.require_admin_auth Topic_paragraphs.delete);

    Dream.get "/admin/tasks" (Auth.require_admin_auth Admin_tasks_manage.list);
    Dream.get "/admin/tasks/:id" (Auth.require_admin_auth Admin_tasks_manage.get_one);

    Dream.post "/admin/tasks" (Auth.require_admin_auth Admin_tasks.create);
    Dream.put "/admin/tasks/:id/archive" (Auth.require_admin_auth Admin_tasks.archive);
    Dream.put "/admin/tasks/:id/unarchive" (Auth.require_admin_auth Admin_tasks.unarchive);
    Dream.post "/admin/tasks/:id/tests" (Auth.require_admin_auth Admin_tests.add);
    Dream.get "/admin/tasks/:id/tests" (Auth.require_admin_auth Admin_tests_manage.list);
    Dream.delete "/admin/task-tests/:test_id" (Auth.require_admin_auth Admin_tests_manage.delete);
  ]
