A comprehensive administration system for QBCore servers that allows authorized admins to manage players via a radial menu or chat command. It features a database-integrated ban system and a professional rejection screen.

**Authorization Mechanism**
Verification is based on the player's license compared against the `Config.AdminSystem` list; anyone not on this list will not see the admin option at all and cannot execute the command.
Checks are performed on both the client side (to toggle the option's visibility) and the server side (for every event/action) to prevent unauthorized players from directly triggering events.

**Menu Access Methods**
**Radial Menu:** The "System" option appears automatically only for authorized admins; it is dynamically added or removed every 5 seconds based on the player's status (enabled via `Config.Command.UseRadial`).
**Chat Command:** A customizable command (defaulting to `/ban`) with an auto-suggestion feature in the chat (enabled via `Config.Command.Enable`).

Upon opening, the server retrieves a list of all connected players (Name, ID, License) and displays them in an interactive menu using `ox_lib`.

**Tablet Animation**
When a player menu is opened, a tablet prop is prepared, and a realistic animation of the player using it is triggered (controlled by `Config.UseAnimation`); the prop is automatically removed when the menu is closed. Available Actions per Player
Action	Description
Ban Player	Input field for the reason + duration selection from a predefined list, with a confirmation prompt before execution.
Send txAdmin Message	Sends a direct message to the target player via the txAdmin system.
Send Notification	Sends a notification to the player with a selectable type (Error / Standard).
Teleport to Player	Instantly teleports to the target player's coordinates with a fade-in/fade-out effect.
Ban System
When a banned player attempts to join the server, they are intercepted during the `playerConnecting` event before actually entering.
A professional "Adaptive Card" is displayed, containing:
Ban reason
Ban date
Expiration date (or "Permanent" if the duration is 0)
Real-time countdown of remaining time (years/days/hours/minutes/seconds)
Button linking to Discord (Config.Discord)
If the ban expires during the connection attempt, the record is automatically deleted from the database, and the player is allowed to join without manual administrative intervention.
Bans are stored using the `license` as a UNIQUE key; if the same person is banned again, the existing record is updated instead of creating a duplicate.
Customizable Settings (config.lua)
Config.Discord: Discord link displayed on the ban card.
Config.BanTable: Database table name.
Config.UseAnimation: Enable/disable tablet animation.
Config.Command: Command activation, radial menu activation, and command name.
Config.AdminSystem: List of authorized admin licenses.
Config.Bans: List of available ban durations (from 2 hours to permanent). Database

The `ab_bans` table is a simple table that stores the license, reason, expiration time (0 = permanent), and ban date—with an index on the license to ensure fast lookups during every login attempt.

#ab_dev
