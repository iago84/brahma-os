import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "BRAHMA — Supreme Intelligence",
  description: "Knowledge is an evolving architecture.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body style={{margin:0,background:"#090A0D",color:"#EAE4D7",fontFamily:"Inter,Arial,sans-serif"}}>{children}</body></html>;
}
