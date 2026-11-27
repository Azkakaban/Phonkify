# Phonkify Google Authentication Setup

Flutter-side Google OAuth buttons and profile initialization have been added. OAuth credentials still need to be configured in Google Cloud and Supabase.

## 1. Google Cloud Console
- Create/select a project and configure OAuth consent screen.
- Create OAuth client credentials appropriate for Supabase's Google provider.
- Use Supabase's callback URL as the redirect URI for the Google OAuth client (copy the exact callback URL shown in Supabase Auth > Providers > Google).
- Keep the client ID and secret available for Supabase configuration.

## 2. Supabase
- Open Authentication > Providers > Google and enable it.
- Paste the Google client ID and secret.
- In Authentication > URL Configuration, add `phonkify://auth-callback` to the allowed redirect URLs.
- Ensure the existing `profiles` table has columns `id`, `username`, `display_name`, `avatar_url` and that `id` references auth.users. The profile role column should have its existing default.

## 3. App behavior
- Existing email/password login and registration are unchanged.
- Google buttons are available on Login and Register pages.
- OAuth returns to `phonkify://auth-callback`.
- The app ensures a profile exists; Google display name is used as display_name, username is generated with a UID suffix, and Google avatar URL is stored if supplied.
- Username is not editable through the existing Edit Profile page; display name and avatar remain editable.
