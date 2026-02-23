# RBAC (Role-Based Access Control)

Module: `Liteskill.Rbac`

The RBAC context controls **system-wide actions** through permission-based roles assigned to users and groups. This is orthogonal to the [Authorization](authorization.md) context, which handles per-resource (entity-level) access control via ACLs.

## Concepts

### Permissions

A permission is a string like `"conversations:create"` or `"admin:users:manage"`. The full list of permissions is defined in `Liteskill.Rbac.Permissions` and organized by domain:

| Domain | Permissions |
|--------|------------|
| `conversations` | `create`, `delete_any`, `view_all` |
| `mcp_servers` | `create`, `manage_global`, `view_all` |
| `groups` | `create`, `manage_all` |
| `agents` | `create`, `manage_all` |
| `teams` | `create`, `manage_all` |
| `runs` | `create`, `manage_all` |
| `reports` | `create`, `manage_all` |
| `sources` | `create`, `manage_all` |
| `wiki_spaces` | `create`, `manage_all` |
| `schedules` | `create`, `manage_all` |
| `llm_providers` | `manage` |
| `llm_models` | `manage` |
| `admin` | `users:view`, `users:manage`, `users:invite`, `roles:manage`, `settings:manage`, `usage:view` |

The special wildcard permission `"*"` grants full access to all permissions.

### Roles

A role is a named bundle of permissions. Roles can be:

- **System roles** -- Created and managed by the application. Cannot be deleted or renamed. Updated on every boot via `ensure_system_roles/0`.
- **Custom roles** -- Created by admins through the UI.

#### System Roles

| Role | Permissions | Description |
|------|------------|-------------|
| `Instance Admin` | `*` (wildcard) | Full system access |
| `Default` | 10 create-level permissions | Baseline permissions applied to all users |

The `Default` role permissions are: `conversations:create`, `groups:create`, `agents:create`, `teams:create`, `runs:create`, `reports:create`, `sources:create`, `wiki_spaces:create`, `schedules:create`, `mcp_servers:create`.

### Permission Resolution

A user's effective permissions are the union of:

1. **Direct role permissions** -- Permissions from roles assigned directly to the user via `user_roles`
2. **Group role permissions** -- Permissions from roles assigned to any group the user belongs to via `group_roles`
3. **Default role permissions** -- Permissions from the `Default` system role (applied to all users)

If any of these sources includes the wildcard `"*"`, the user is granted all defined permissions.

## Schemas

- `Liteskill.Rbac.Role` -- Role definition with name, description, system flag, and permissions array
- `Liteskill.Rbac.UserRole` -- Join table linking users to roles (unique on `user_id, role_id`)
- `Liteskill.Rbac.GroupRole` -- Join table linking groups to roles (unique on `group_id, role_id`)
- `Liteskill.Rbac.Permissions` -- Module defining the canonical list of valid permissions

## Key Functions

### Permission Checking

- `has_permission?(user_id, permission)` -- Returns `true` if the user has the given permission
- `list_permissions(user_id)` -- Returns a `MapSet` of all effective permissions for the user
- `authorize(user_id, permission)` -- Returns `:ok` or `{:error, :forbidden}`
- `has_any_admin_permission?(user_id)` -- Returns `true` if the user has any admin-level permission (used for admin UI access)

### Role CRUD

- `list_roles/0` -- Lists all roles, system roles first
- `get_role/1`, `get_role_by_name!/1` -- Role lookups
- `create_role/1`, `update_role/2`, `delete_role/1` -- Standard CRUD (system roles cannot be deleted; system role names cannot be changed)

### Role Assignments

- `assign_role_to_user/2`, `remove_role_from_user/2` -- Direct user-role assignments
- `assign_role_to_group/2`, `remove_role_from_group/2` -- Group-role assignments
- `list_user_roles/1`, `list_group_roles/1` -- Query roles for a user/group
- `list_role_users/1`, `list_role_groups/1` -- Query users/groups for a role

### Boot-Time Seeding

- `ensure_system_roles/0` -- Upserts the `Instance Admin` and `Default` system roles, then migrates existing admin users (those with `role: "admin"` in the users table) to the `Instance Admin` RBAC role. Called from the application boot task.

## RBAC vs Entity ACLs

| Aspect | RBAC (`Liteskill.Rbac`) | Entity ACLs (`Liteskill.Authorization`) |
|--------|------------------------|----------------------------------------|
| Scope | System-wide actions | Per-resource access |
| Question answered | "Can this user create conversations?" | "Can this user view this specific conversation?" |
| Assignment | Roles assigned to users/groups | ACL entries on specific entities |
| Roles | Custom permission bundles | Fixed: owner, manager, editor, viewer |
| Tables | `roles`, `user_roles`, `group_roles` | `entity_acls` |

## Database Tables

See [Database: RBAC Tables](../architecture/database.md#rbac-tables) for full schema details.
