import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Online Shopping Mall',
  description: '온라인 쇼핑몰',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
