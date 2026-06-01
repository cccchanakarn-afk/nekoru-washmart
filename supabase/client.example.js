// Supabase client — drop this into the page after Supabase is provisioned.
// 1. Add the CDN script to index.html <head>:
//      <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
// 2. Replace the placeholders below with your project URL + anon key
//    (find them at: Supabase Studio → Project Settings → API).
// 3. The anon key is SAFE to expose in the browser — Row Level Security in
//    schema.sql controls what it can read/write. NEVER ship the service_role key.

const SUPABASE_URL = 'https://YOUR-PROJECT-ref.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOi...';   // public anon key

const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ---------- Example: submit contact form to Supabase ----------
// (alternative to Netlify Forms — pick one path)
async function submitContact(form) {
  const fd = new FormData(form);
  const subjectMap = {
    'สอบถามทั่วไป': 'general',
    'ปัญหาการใช้งานเครื่อง': 'machine_issue',
    'เสนอแฟรนไชส์ / เปิดสาขา': 'franchise',
    'ร่วมงาน / สมัครงาน': 'careers',
    'ติชม / ข้อเสนอแนะ': 'feedback',
  };
  const { error } = await supabase.from('contacts').insert({
    name:    fd.get('name'),
    phone:   fd.get('phone'),
    subject: subjectMap[fd.get('subject')] || 'general',
    message: fd.get('message'),
    consent: !!fd.get('consent'),
    user_agent: navigator.userAgent,
  });
  if (error) { alert('ส่งไม่สำเร็จ: ' + error.message); return; }
  alert('ส่งข้อความเรียบร้อย! ทีมงานจะติดต่อกลับ');
  form.reset();
}

// ---------- Example: fetch open branches for the Branches section ----------
async function loadBranches() {
  const { data, error } = await supabase
    .from('branches')
    .select('slug, name_th, address_th, district, status, google_maps_url, features')
    .in('status', ['open', 'coming_soon'])
    .order('opened_at', { ascending: true });
  if (error) console.error(error);
  return data || [];
}

// ---------- Example: fetch published articles ----------
async function loadArticles(limit = 3) {
  const { data } = await supabase
    .from('articles')
    .select('slug, category, title_th, excerpt_th, cover_image_url, read_minutes, published_at')
    .not('published_at', 'is', null)
    .lte('published_at', new Date().toISOString())
    .order('published_at', { ascending: false })
    .limit(limit);
  return data || [];
}
