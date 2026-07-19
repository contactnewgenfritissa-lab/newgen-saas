'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabase'

export function AuthGuard({children}:{children:React.ReactNode}){
 const [ready,setReady]=useState(false); const router=useRouter()
 useEffect(()=>{supabase.auth.getSession().then(({data})=>{if(!data.session) router.replace('/login'); else setReady(true)})},[router])
 if(!ready) return <div className="min-h-screen grid place-items-center"><div className="w-12 h-12 rounded-full border-4 border-violet-200 border-t-violet-600 animate-spin"/></div>
 return children
}
