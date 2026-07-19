import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'New Gen Orders',
  description: 'منصة احترافية لإدارة وتأكيد الطلبات',
}

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ar" dir="rtl">
      <body>{children}</body>
    </html>
  )
}
