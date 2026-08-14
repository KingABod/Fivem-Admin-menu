A comprehensive administration system for QBCore servers that allows authorized admins to manage players through a custom-built interactive NUI panel, accessible via a radial menu or chat command. It features a database-integrated ban system, a full moderation dashboard, and a professional rejection screen.

Authorization Mechanism
Verification is based on the player's license compared against the `Config.AdminSystem` list; anyone not on this list will not see the admin option at all and cannot open the panel. Checks are performed on both the client side (to toggle the radial option's visibility and gate the command) and the server side (for every event/action — GetPlayers, GetBans, GetLogs, BanPlayer, UnbanPlayer, SendDM, SendNotify) to prevent unauthorized players from directly triggering events, even if they bypass the client UI.

Menu Access Methods
Radial Menu: The "System" option appears automatically only for authorized admins; it is dynamically added or removed every 5 seconds based on the player's status (enabled via `Config.Command.UseRadial`).
Chat Command: A customizable command (defaulting to `/ban`) with an auto-suggestion feature in the chat (enabled via `Config.Command.Enable`).
Both methods open the same NUI panel — the radial option and the command are just two triggers for one interface.

Admin Panel (NUI)
Upon opening, the server retrieves a list of all connected players (Name, ID, License, Citizen ID, Job, Duty Status, Ping, Coordinates) and streams it into a custom HTML/CSS/JS interface with full mouse and keyboard support (closable via the on-screen button or ESC). The panel is organized into four tabs:

- Dashboard: Live counters for online players, active bans, permanent bans, and total logged admin actions, plus a rolling feed of the most recent activity.
- Players: A searchable list (by name, ID, or license) of every connected player. Each entry expands into an inline action drawer with four sub-tabs — Ban, Message, Notify, Teleport — so all actions are handled in one place without separate popup dialogs.
- Bans: A live, searchable list of every active ban pulled from the database, showing the reason, the admin who issued it, the ban date, and either the countdown to expiry or a "Permanent" tag. Each record can be lifted (unbanned) directly from the panel.
- Activity Log: The last 50 admin actions (bans, unbans, messages, notifications), each attributed to the admin who performed it, the target, and a relative timestamp — all pulled from a dedicated database table.

Tablet Animation
When the panel is opened, a tablet prop is prepared, and a realistic animation of the player using it is triggered (controlled by `Config.UseAnimation`); the prop is automatically removed when the panel is closed.

Available Actions per Player
| Action | Description |
|---|---|
| Ban Player | Input field for the reason + duration selection from a predefined list, submitted directly from the inline drawer. |
| Send txAdmin Message | Sends a direct message to the target player via the txAdmin system. |
| Send Notification | Sends a notification to the player with a selectable type (Error / Primary). |
| Teleport to Player | Instantly teleports to the target player's coordinates with a fade-out/fade-in effect. |
| Lift Ban | Removes an active ban record from the Bans tab without needing the player's ID or presence online. |

Ban System
When a banned player attempts to join the server, they are intercepted during the `playerConnecting` event before actually entering. A professional Adaptive Card is displayed, containing:
- Ban reason
- Ban date
- Expiration date (or "Permanent" if the duration is 0)
- Real-time countdown of remaining time (years/days/hours/minutes/seconds)
- Button linking to Discord (`Config.Discord`)

If the ban expires during the connection attempt, the record is automatically deleted from the database, and the player is allowed to join without manual administrative intervention. Bans are stored using the `license` as a UNIQUE key; if the same person is banned again, the existing record is updated instead of creating a duplicate — and the admin who issued the ban is recorded alongside it.

Activity Logging
Every ban, unban, message, and notification sent through the panel is written to a dedicated `ab_admin_logs` table with the admin's name, the action type, the target, an optional detail string, and a timestamp — giving a full audit trail of admin activity that's viewable directly in the panel's Activity tab.

Customizable Settings (config.lua)
- `Config.Discord`: Discord link displayed on the ban card.
- `Config.BanTable`: Database table name for bans.
- `Config.LogTable`: Database table name for the activity log.
- `Config.UseAnimation`: Enable/disable tablet animation.
- `Config.UI`: Panel title and subtitle shown in the header.
- `Config.Command`: Command activation, radial menu activation, and command name.
- `Config.AdminSystem`: List of autho

#**Ban**
<img width="1021" height="652" alt="image" src="https://github.com/user-attachments/assets/22cc5225-8fc4-47e1-b45d-abf92a57eafe" />
<img width="1020" height="679" alt="image" src="https://github.com/user-attachments/assets/a71815d1-9043-43f0-9063-f46d62ff2841" />

#**UI**
<img width="2559" height="1439" alt="image" src="https://github.com/user-attachments/assets/570ed28c-0f74-49d6-98a2-f2aafa674c2d" />
<img width="2559" height="1439" alt="image" src="https://github.com/user-attachments/assets/bdb87a19-2484-4722-81b7-357ded16856f" />
<img width="2556" height="1439" alt="image" src="https://github.com/user-attachments/assets/4d93656d-d81d-4515-ba38-588a4dfaba39" />

#ab_dev
