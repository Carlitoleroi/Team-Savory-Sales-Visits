# Team Savory Sales Visits

A mobile-first field-sales visit reporting app with:

- Email magic-link sign-in
- Shared Supabase database
- Rep-level access and manager/admin visibility
- Customer visit capture
- Product selections
- Opportunity values
- Photo upload
- Follow-up tracking
- Weekly dashboard
- CSV export

## 1. Create the Supabase project

Create a Supabase project, then open **SQL Editor** and run `supabase.sql`.

## 2. Configure the app

Copy `config.example.js` to `config.js` and replace:

- `supabaseUrl`
- `supabaseAnonKey`
- `products`
- company/app name if desired

The Supabase anon key is intended for browser use. Access is protected by Row Level Security policies in `supabase.sql`. Never put the Supabase service-role key in this app.

## 3. Auth settings

In Supabase Authentication > URL Configuration:

- Set Site URL to your deployed site URL.
- Add your local/deployment URL to Redirect URLs.

You may leave email confirmations enabled. The app uses a magic link, so users do not need passwords.

## 4. Make managers

After a manager signs in once, run this in Supabase SQL Editor:

```sql
update public.profiles
set role = 'manager'
where id = (select id from auth.users where email = 'manager@yourcompany.com');
```

Managers can see all visits. Reps can only see their own.

## 5. Deploy

This is a static site. Deploy the folder to GitHub Pages, Netlify, Vercel, Cloudflare Pages, or another static host.

For GitHub Pages, upload the files to a repository and enable Pages from the repository Settings > Pages screen.

## 6. Test before rollout

Test these flows:

1. Rep signs in from a phone.
2. Rep submits a visit with and without a photo.
3. Rep sees only their own visits.
4. Manager sees all reps' visits and weekly dashboard totals.
5. CSV export works.
6. Follow-up dates appear correctly.

## Files

- `index.html` — application
- `config.js` — live configuration (create from example)
- `config.example.js` — configuration template
- `supabase.sql` — database, security, auth profile trigger, and photo storage setup
