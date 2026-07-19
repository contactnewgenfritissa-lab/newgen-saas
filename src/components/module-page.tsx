'use client';
import { ReactNode } from 'react';
import AppShell from './app-shell';
import AuthGuard from './auth-guard';
export default function ModulePage({title,subtitle,children}:{title:string;subtitle:string;children:ReactNode}){
 return <AuthGuard><AppShell><section className="module-head"><div><p className="eyebrow">NEW GEN OPERATIONS</p><h1>{title}</h1><p>{subtitle}</p></div></section>{children}</AppShell></AuthGuard>
}
