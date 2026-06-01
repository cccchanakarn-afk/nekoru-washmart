// Netlify Function: notify-contact
//
// Receives a Supabase Database Webhook on INSERT to public.contacts
// and forwards as an email via Resend.
//
// Required Netlify environment variables (Site config → Build & deploy → Environment):
//   RESEND_API_KEY     — from https://resend.com/api-keys
//   NOTIFY_TO_EMAIL    — where to send the notification (e.g. wegomeow.8@gmail.com)
//   NOTIFY_FROM_EMAIL  — verified sender, e.g. onboarding@resend.dev (testing only,
//                        delivers to your own verified address) or notify@yourdomain.com
//   WEBHOOK_SECRET     — shared secret; Supabase webhook sends it as header
//                        x-nekoru-secret. If unset, the check is skipped (not recommended).

const SUBJECT_LABEL = {
  general:       'สอบถามทั่วไป',
  machine_issue: 'ปัญหาการใช้งานเครื่อง',
  franchise:     'เสนอแฟรนไชส์ / เปิดสาขา',
  careers:       'ร่วมงาน / สมัครงาน',
  feedback:      'ติชม / ข้อเสนอแนะ',
};

function esc(s){ return String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

export const handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  // Optional shared-secret check
  const expected = process.env.WEBHOOK_SECRET;
  if (expected) {
    const got = event.headers['x-nekoru-secret'] || event.headers['X-Nekoru-Secret'];
    if (got !== expected) {
      return { statusCode: 401, body: 'unauthorized' };
    }
  }

  let payload;
  try { payload = JSON.parse(event.body || '{}'); }
  catch { return { statusCode: 400, body: 'invalid JSON' }; }

  // Supabase webhook payload shape: { type, table, schema, record, old_record }
  if (payload.type !== 'INSERT' || payload.table !== 'contacts' || !payload.record) {
    return { statusCode: 200, body: 'ignored' };
  }
  const r = payload.record;
  const subjectTh = SUBJECT_LABEL[r.subject] || r.subject || '—';

  const apiKey = process.env.RESEND_API_KEY;
  const toRaw  = process.env.NOTIFY_TO_EMAIL || '';
  const from   = process.env.NOTIFY_FROM_EMAIL || 'onboarding@resend.dev';
  const to     = toRaw.split(',').map(s => s.trim()).filter(Boolean);
  if (!apiKey || to.length === 0) {
    console.error('Missing RESEND_API_KEY or NOTIFY_TO_EMAIL');
    return { statusCode: 500, body: 'server not configured' };
  }

  const html = `
    <div style="font-family:system-ui,sans-serif;max-width:560px;margin:0 auto;padding:24px;color:#0e2c40">
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:16px">
        <span style="font-size:28px">😺</span>
        <strong style="font-size:18px;color:#31a7de">Nekoru Washmart</strong>
      </div>
      <h2 style="margin:0 0 8px;font-size:20px">📥 มีข้อความใหม่จากเว็บไซต์</h2>
      <p style="color:#5d7587;margin:0 0 20px;font-size:13px">${esc(new Date(r.created_at || Date.now()).toLocaleString('th-TH', { dateStyle: 'medium', timeStyle: 'short' }))}</p>
      <table style="width:100%;border-collapse:collapse;font-size:14px;background:#f4fbff;border-radius:12px;overflow:hidden">
        <tr><td style="padding:10px 14px;font-weight:bold;width:120px;color:#5d7587">ชื่อ</td><td style="padding:10px 14px">${esc(r.name)}</td></tr>
        <tr><td style="padding:10px 14px;font-weight:bold;color:#5d7587;border-top:1px solid #e6f3fa">เบอร์ / LINE</td><td style="padding:10px 14px;border-top:1px solid #e6f3fa">${esc(r.phone)}</td></tr>
        <tr><td style="padding:10px 14px;font-weight:bold;color:#5d7587;border-top:1px solid #e6f3fa">หัวข้อ</td><td style="padding:10px 14px;border-top:1px solid #e6f3fa">${esc(subjectTh)}</td></tr>
        <tr><td style="padding:10px 14px;font-weight:bold;color:#5d7587;border-top:1px solid #e6f3fa;vertical-align:top">ข้อความ</td><td style="padding:10px 14px;border-top:1px solid #e6f3fa;white-space:pre-wrap">${esc(r.message)}</td></tr>
      </table>
      <p style="margin-top:24px;font-size:12px;color:#5d7587">
        ดูทั้งหมดที่
        <a href="https://nekoru-washmart.netlify.app/admin.html" style="color:#31a7de">Admin Console</a>
      </p>
    </div>`;

  const text = [
    'มีข้อความใหม่จาก Nekoru',
    '',
    `เวลา : ${new Date(r.created_at || Date.now()).toLocaleString('th-TH')}`,
    `ชื่อ : ${r.name}`,
    `เบอร์ : ${r.phone}`,
    `หัวข้อ : ${subjectTh}`,
    '',
    'ข้อความ:',
    r.message,
    '',
    '— Nekoru Washmart',
  ].join('\n');

  const resp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from,
      to,
      subject: `[Nekoru] ${subjectTh}: ${r.name}`,
      html, text,
    }),
  });

  const json = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    console.error('Resend error:', resp.status, json);
    return { statusCode: 502, body: JSON.stringify({ error: 'email send failed', detail: json }) };
  }
  return { statusCode: 200, body: JSON.stringify({ ok: true, id: json.id }) };
};
