# TechZone — Final Static + Supabase Edition

ئەم وەشانە بۆ GitHub Pages دروست کراوە و پاشکۆی Supabase هەیە.

## 1) GitHub Pages
لە repository ـەکە:
Settings → Pages → Build and deployment
- Source: Deploy from a branch
- Branch: main
- Folder: /(root)
- Save

پێویستە `index.html` لە root ـی repository بێت.

## 2) Supabase
لە Supabase:
- Project URL و Publishable key وەربگرە.
- لە `app.js` ئەمانە بگۆڕە:
  SUPABASE_URL
  SUPABASE_KEY

تەنها Publishable key/anon key بۆ browser بەکاربهێنە. Secret/service_role key مەخە GitHub.

## 3) Database
ئەگەر schema ـی پێشووەکەت هەمان ناوەکان (`categories`, `products`, `profiles`, `orders`, `order_items`) هەیە، frontend بۆ ئەوان نووسراوە.
فایلی `supabase.sql` لە package ـەکە schema ـی پێشنیارکراوی نوێیە؛ پێش جێبەجێکردن لە project ـی هەنووکەیی backup بگرە و schema ـی پێشووت لەگەڵی هاوتا بکە.

## 4) Admin
`login.html` بۆ Supabase Auth ـە.
دوای دروستکردنی user، role ـی profile ـەکە بکە admin.
لە frontend هیچ secret/service_role key دانەنرێت.

## 5) Production
ئەم وەشانە UI + frontend + Supabase integration ـی بنەڕەتییە. بۆ production پێویستە:
- payment gateway ـی واقعی
- image upload/storage
- email/SMS notifications
- stronger server-side order validation
- audit logs
- rate limiting
- shipping integration
