"use client";

import { useState } from "react";

const API = process.env.NEXT_PUBLIC_BRAHMA_API ?? "http://127.0.0.1:8000/api/v1";

export default function Home() {
  const [message, setMessage] = useState("");
  const [answer, setAnswer] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function send() {
    if (!message.trim() || busy) return;
    setBusy(true); setError(""); setAnswer("");
    try {
      const res = await fetch(`${API}/chat`, {
        method: "POST",
        headers: {"Content-Type":"application/json"},
        body: JSON.stringify({message}),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.detail ?? "BRAHMA could not answer.");
      setAnswer(data.answer);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Connection error");
    } finally { setBusy(false); }
  }

  return <main style={{maxWidth:900,margin:"0 auto",padding:"64px 24px"}}>
    <header style={{textAlign:"center",marginBottom:64}}>
      <div style={{color:"#C6A15B",letterSpacing:8,fontSize:12}}>NAIRA STUDIO PRESENTS</div>
      <h1 style={{fontSize:56,letterSpacing:10,margin:"18px 0 4px",color:"#D6B46F"}}>BRAHMA</h1>
      <div style={{letterSpacing:4,fontSize:11,color:"#A9A49A"}}>SUPREME INTELLIGENCE</div>
      <p style={{color:"#A9A49A",fontStyle:"italic"}}>Knowledge is an evolving architecture.</p>
    </header>
    <section style={{border:"1px solid #39342B",borderRadius:18,padding:24,background:"#111216"}}>
      <h2 style={{fontWeight:500}}>Ask BRAHMA</h2>
      <textarea value={message} onChange={e=>setMessage(e.target.value)}
        placeholder="Explore an idea, connect concepts, ask a question..."
        rows={5} style={{width:"100%",boxSizing:"border-box",background:"#090A0D",color:"#EAE4D7",border:"1px solid #39342B",borderRadius:10,padding:14,fontSize:15}} />
      <button onClick={send} disabled={busy || !message.trim()}
        style={{marginTop:14,background:"#C6A15B",color:"#090A0D",border:0,borderRadius:8,padding:"12px 22px",fontWeight:700,cursor:"pointer"}}>
        {busy ? "Thinking..." : "Consult BRAHMA"}
      </button>
      {error && <p style={{color:"#F08A8A"}}>{error}</p>}
      {answer && <article style={{whiteSpace:"pre-wrap",lineHeight:1.7,marginTop:24,borderTop:"1px solid #39342B",paddingTop:20}}>{answer}</article>}
    </section>
    <footer style={{textAlign:"center",color:"#77736B",fontSize:11,marginTop:48}}>BRAHMA CORE 0.1 · LOCAL KNOWLEDGE ENGINE</footer>
  </main>;
}
