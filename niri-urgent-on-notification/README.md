# Niri Urgent Windows

Noctalia v5 Luau service for marking matching Niri windows urgent through IPC:

```sh
noctalia msg plugin noctalia/niri-urgent-on-notification:urgent-service all urgent app-id
noctalia msg plugin noctalia/niri-urgent-on-notification:urgent-service all clear app-id
```

Automatic notification tracking is unavailable because v5 currently has no notification-received plugin hook.
