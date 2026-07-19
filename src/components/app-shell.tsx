'use client'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { BarChart3, Box, LogOut, PhoneCall, Settings, Users } from 'lucide-react'
import { supabase } from '@/lib/supabase'

const links=[
  {href:'/dashboard',label:'لوحة التحكم',icon:BarChart3},
  {href:'/orders',label:'الطلبيات',icon:Box},
  {href:'/orders?status=callback',label:'إعادة الاتصال',icon:PhoneCall},
  {href:'/users',label:'المستخدمون',icon:Users},
]

export function AppShell({children}:{children:React.ReactNode}){
  const path=usePathname(); const router=useRouter()
  async function logout(){await supabase.auth.signOut();router.replace('/login')}
  return <div className="min-h-screen lg:grid lg:grid-cols-[280px_1fr]">
    <aside className="brand-gradient text-white p-5 lg:min-h-screen">
      <div className="flex items-center gap-3 mb-8"><div className="w-12 h-12 rounded-2xl bg-white/15 grid place-items-center font-extrabold">NG</div><div><b className="text-lg">New Gen</b><div className="text-white/70 text-sm">Orders Platform</div></div></div>
      <nav className="grid gap-2">{links.map(({href,label,icon:Icon})=><Link key={href} href={href} className={`flex items-center gap-3 rounded-2xl px-4 py-3 font-bold transition ${path===href.split('?')[0]?'bg-white/18':'hover:bg-white/10 text-white/80'}`}><Icon size={20}/>{label}</Link>)}</nav>
      <div className="mt-8 pt-5 border-t border-white/15 grid gap-2"><button className="flex items-center gap-3 px-4 py-3 rounded-2xl hover:bg-white/10"><Settings size={20}/>الإعدادات</button><button onClick={logout} className="flex items-center gap-3 px-4 py-3 rounded-2xl bg-rose-500/20 hover:bg-rose-500/30"><LogOut size={20}/>تسجيل الخروج</button></div>
    </aside>
    <main className="p-4 md:p-7">{children}</main>
  </div>
}
