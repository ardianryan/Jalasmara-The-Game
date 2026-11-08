import { connect, close } from "./db.js";
import { buildApp } from "./app.js";
const store = await connect();
const app = await buildApp(store);
await app.listen({
  host: process.env.HOST ?? "127.0.0.1",
  port: Number(process.env.PORT ?? 3000),
});
for (const sig of ["SIGTERM", "SIGINT"] as const)
  process.on(sig, async () => {
    await app.close();
    await close(store);
    process.exit(0);
  });
