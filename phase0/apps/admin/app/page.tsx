export default function HomePage() {
  return (
    <main className="min-h-screen bg-slate-950 text-slate-50 flex items-center justify-center">
      <section className="max-w-xl text-center space-y-6">
        <p className="text-sm uppercase tracking-[0.3em] text-slate-400">APP XXX — Admin Shell</p>
        <h1 className="text-3xl font-semibold">Benvenuto nella console amministrativa</h1>
        <p className="text-base text-slate-300">
          Questa è una shell Next.js minimale pronta per essere estesa con autenticazione, dashboard e
          strumenti operativi nelle fasi successive.
        </p>
      </section>
    </main>
  );
}
