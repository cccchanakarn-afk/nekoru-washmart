# Nekoru Washmart — Landing Page

ร้านสะดวกซักเนโกะรุ · ซัก-อบในเครื่องเดียว 24 ชั่วโมง

## โครงสร้าง

```
.
├── index.html            # หน้า Landing Page (static, Tailwind via CDN)
├── i18n-seq.js           # ลำดับข้อความภาษาอังกฤษ ใช้กับปุ่มสลับภาษา
├── assets/               # รูปภาพทั้งหมด (logo, mascot, ไอคอน, QR)
├── netlify.toml          # config สำหรับ Netlify (publish dir, cache headers)
└── supabase/             # SQL schema + setup guide สำหรับ database
    ├── schema.sql
    ├── client.example.js
    └── README.md
```

## รันในเครื่อง

```bash
npx http-server . -p 8080 -c-1
# เปิด http://127.0.0.1:8080
```

## Deploy

Hosting: **Netlify** (auto-deploy จาก GitHub) — ดู section "Deploy" ในบทสนทนา

Database: **Supabase** (Free tier, Singapore region) — ดู [`supabase/README.md`](supabase/README.md)

## Tech stack

- HTML + Tailwind CSS (via CDN)
- Vanilla JS (ภาษา toggle, calculator, FAQ tabs)
- ฟอนต์: LINE Seed Sans TH, Prompt, Sarabun (Google Fonts + jsDelivr)
