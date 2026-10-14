# 連絡先検索（Supabase接続済み）

このフォルダは Supabase `contacts-db` に接続する静的Webアプリです。

## すでに設定済み
- Supabase Project URL: 設定済み
- Publishable key: 設定済み
- パスワード、Database password、service_role/secret key は含みません

## 使用前にSupabase側で必要なこと
1. Authentication > Users に検索用ユーザーを1人作る。
2. SQL Editorで、そのユーザーのメールアドレスを allowlist に登録する。

```sql
insert into public.app_allowed_user (email, note)
values (lower('YOUR_EMAIL'), '連絡先DB管理者')
on conflict (email) do update
set note = excluded.note;
```

3. `search_contacts` RPC と RLS が作成済みであること。

## 公開方法
このフォルダの内容を HTTPS で配信してください。GitHub Pages / Netlify / Vercel などの静的ホスティングで動きます。

GitHub Pagesの場合は、このフォルダのファイルをリポジトリのルートへ置き、Settings > Pages から公開します。

## iPhone
公開URLをSafariで開く → ログイン → 共有 →「ホーム画面に追加」。

## セキュリティ
`config.js` の Publishable key はブラウザ配布用です。データ保護はSupabaseの認証とRLSで行います。
`service_role` / secret key / Database password は絶対にこのフォルダへ入れないでください。
