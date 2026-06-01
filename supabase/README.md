# Supabase setup — Nekoru Washmart

## 1. สร้างโปรเจกต์ (ฟรี)

1. ไปที่ <https://supabase.com> → **Start your project** → ล็อกอินด้วย GitHub
2. **New project**
   - Name: `nekoru-washmart`
   - Database password: สุ่มมาแล้วเก็บไว้ที่ปลอดภัย (เช่น Password manager)
   - Region: **Southeast Asia (Singapore)** — ใกล้ไทยที่สุด
   - Pricing plan: **Free** (500MB DB, 1GB storage, 50k MAU)
3. รอประมาณ 1-2 นาทีให้สร้างเสร็จ

## 2. รัน schema

1. เปิด **SQL Editor** (เมนูซ้าย) → **+ New query**
2. คัดลอกทั้งหมดจาก [`schema.sql`](./schema.sql) → วาง → **Run** (Ctrl+Enter)
3. ดูว่าข้างล่างขึ้น `Success. No rows returned` → เสร็จ
4. กดเมนู **Table Editor** ตรวจดูว่ามีตาราง: `contacts`, `members`, `branches`,
   `articles`, `news_events`, `franchise_inquiries`, `career_applications`, `faqs`,
   `newsletter_subscribers`, `member_points_log`

## 3. หา API keys

**Project Settings** (เฟืองล่างซ้าย) → **API**

| Key | ใช้ตรงไหน | ห้ามเผยแพร่? |
|---|---|---|
| `Project URL` | ใส่ในหน้าเว็บ (browser) | ปลอดภัย ใส่ได้ |
| `anon` (public) | ใส่ในหน้าเว็บ (browser) | **ปลอดภัย** — RLS คุมสิทธิ์ |
| `service_role` (secret) | server-side / admin script เท่านั้น | **อย่าเอาขึ้น GitHub / ฝั่ง browser เด็ดขาด** |

## 4. ทดสอบส่งข้อความเข้า `contacts`

ใน SQL Editor:

```sql
insert into contacts (name, phone, subject, message)
values ('ทดสอบ', '0812345678', 'general', 'Hello Nekoru');

select * from contacts order by created_at desc limit 5;
```

ถ้าได้ row กลับมา = พร้อมใช้

## 5. เชื่อมกับเว็บ (เมื่อพร้อม)

ดูตัวอย่างใน [`client.example.js`](./client.example.js) — มีฟังก์ชัน
`submitContact`, `loadBranches`, `loadArticles` ตัวอย่าง

**สรุป path การส่งฟอร์มติดต่อ:**
- **ตอนนี้:** ใช้ Netlify Forms (auto-detect จาก `data-netlify="true"`) — ไม่ต้องเขียนโค้ดเลย
- **อนาคต:** สลับมาเขียน Supabase ตอนต้องการ dashboard ที่ปรับแต่งได้ + รวมกับระบบสมาชิก

## 6. กันโปรเจกต์โดน pause

Free tier จะ pause ถ้าไม่มีการใช้งาน 7 วัน วิธีกัน:

- เข้า dashboard ทุก ~1 สัปดาห์
- หรือสร้าง cron จาก [cron-job.org](https://cron-job.org) (ฟรี) ยิง health check ไปที่
  `https://YOUR-PROJECT.supabase.co/rest/v1/branches?select=id&limit=1`
  พร้อม header `apikey: <ANON_KEY>` ทุก 3 วัน
