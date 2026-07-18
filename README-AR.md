# New Gen SaaS v1

منصة عربية لإدارة تأكيد الطلبات والمتاجر والشحن والتقارير.

## ما تم تضمينه
- Next.js + TypeScript + Supabase.
- تسجيل الدخول والملفات الشخصية.
- الطلبات والمستخدمون.
- المتاجر والعملاء والشحنات.
- التقارير والإشعارات وسجل النشاط والإعدادات.
- ستة أدوار وصلاحيات RLS.

## قاعدة البيانات الحالية
شغّل فقط الملفات التالية بالترتيب داخل Supabase SQL Editor:
1. `supabase/migrations/005_business_modules.sql`
2. `supabase/migrations/006_reports_notifications.sql`
3. `supabase/migrations/007_optional_demo_seed.sql` اختياري.

## متغيرات Vercel
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`

لا ترفع `.env.local` ولا أي Secret key إلى GitHub.
