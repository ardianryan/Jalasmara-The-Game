import { chromium, firefox, webkit, type Page } from "@playwright/test";
import { readFileSync, mkdirSync, writeFileSync } from "node:fs";
const fixture = JSON.parse(readFileSync(".runtime/browser.json", "utf8")),
  base = process.env.BROWSER_BASE ?? "http://localhost:5173";
mkdirSync("artifacts/browser", { recursive: true });
const evidence: any[] = [];
async function login(page: Page, role: string) {
  const u = fixture.accounts.find((u: any) => u.role === role);
  await page.goto(base);
  await page.getByLabel("Email", { exact: true }).fill(u.email);
  await page.getByLabel("Password", { exact: true }).fill(fixture.password);
  await page.getByRole("button", { name: "Masuk ke Jalasmara" }).click();
  await page.waitForURL("**/play");
  await page.goto(`${base}/admin`);
}
async function fits(page: Page, label: string) {
  const width = await page.evaluate(() => ({
    viewport: innerWidth,
    document: document.documentElement.scrollWidth,
  }));
  if (width.document > width.viewport + 1)
    throw new Error(`${label}: overflow ${JSON.stringify(width)}`);
  evidence.push({ label, ...width });
}
for (const [engine, launcher] of Object.entries({
  chromium,
  firefox,
  webkit,
})) {
  const browser = await launcher.launch();
  const context = await browser.newContext({
    viewport: { width: 1440, height: 960 },
  });
  const page = await context.newPage();
  const errors: string[] = [];
  page.on("pageerror", (e) => errors.push(e.message));
  await login(page, "owner");
  await page.getByRole("heading", { name: "Pemain", exact: true }).waitFor();
  await page.getByRole("button", { name: "Undang pemain" }).click();
  await page
    .getByLabel("Email penerima")
    .fill(`browser-${engine}-${Date.now()}@test.invalid`);
  await page
    .getByRole("dialog")
    .getByLabel("Alasan", { exact: true })
    .fill("Pengujian undangan melalui browser");
  await page.getByRole("button", { name: "Terbitkan undangan" }).click();
  await page.getByRole("heading", { name: "Tautan sekali pakai" }).waitFor();
  const invitation = await page
    .getByRole("dialog")
    .getByLabel("Tautan", { exact: true })
    .inputValue();
  if (!/\/activate#[A-Za-z0-9_-]{32,}$/.test(invitation))
    throw new Error("Tautan undangan tidak valid");
  await page.keyboard.press("Escape");

  await page.screenshot({
    path: `artifacts/browser/${engine}-admin.png`,
    fullPage: true,
    animations: "disabled",
  });
  await fits(page, `${engine} admin`);
  const player = fixture.accounts.find((u: any) => u.role === "player");
  const row = page.getByRole("row").filter({ hasText: player.email });
  await row.getByRole("button", { name: "Kelola" }).click();
  await page.getByLabel("Tindakan").selectOption("coins");
  await page.getByLabel("Jumlah", { exact: true }).fill("25");
  await page
    .getByLabel("Alasan perubahan")
    .fill("Pengujian kontrol melalui browser");
  await page.getByRole("button", { name: "Tinjau perubahan" }).click();
  await page.getByRole("button", { name: "Terapkan dan catat audit" }).click();
  await page
    .getByText(
      "Perubahan disimpan bersama audit. Sesi permainan sebelumnya dibatalkan.",
    )
    .waitFor();
  await page.screenshot({
    path: `artifacts/browser/${engine}-admin-detail.png`,
    fullPage: true,
    animations: "disabled",
  });
  await page
    .getByRole("button", { name: "Konten permainan", exact: true })
    .click();
  await page
    .getByRole("row")
    .filter({ hasText: "published" })
    .getByRole("button", { name: "Buka", exact: true })
    .first()
    .click();
  await page.getByRole("button", { name: "Buat draft salinan" }).click();
  await page.getByRole("button", { name: "Konfirmasi", exact: true }).click();
  await page.getByText(/draft · 60 soal/).waitFor();
  await page
    .getByLabel("Pertanyaan", { exact: true })
    .fill(
      `Bagaimana klorofil membantu tumbuhan memanfaatkan energi matahari? (${engine}, ${Date.now()})`,
    );
  await page
    .getByLabel("Alasan penyimpanan/publikasi")
    .fill("Peninjauan soal melalui browser");
  await page.getByRole("button", { name: "Simpan draft" }).click();
  await page.getByText("Draft disimpan. Tinjau sebelum publikasi.").waitFor();
  await page.screenshot({
    path: `artifacts/browser/${engine}-editor.png`,
    fullPage: true,
    animations: "disabled",
  });
  await page.getByRole("button", { name: "Tinjau publikasi" }).click();
  await page.getByRole("button", { name: "Konfirmasi", exact: true }).click();
  await page.getByText("Perubahan konten tercatat.").waitFor();
  await page.getByRole("button", { name: "Jejak audit", exact: true }).click();
  await page
    .getByRole("heading", { name: "Jejak audit", exact: true })
    .waitFor();
  for (const width of [768, 390]) {
    await page.setViewportSize({ width, height: 844 });
    await fits(page, `${engine} audit ${width}`);
    await page.getByRole("button", { name: "Pemain", exact: true }).click();
    await fits(page, `${engine} admin ${width}`);
    await page.screenshot({
      path: `artifacts/browser/${engine}-admin-${width}.png`,
      fullPage: true,
      animations: "disabled",
    });
  }
  await page.getByRole("button", { name: "Keluar dari akun" }).click();
  await fits(page, `${engine} mobile login`);
  if (errors.length)
    throw new Error(`${engine} JS errors: ${errors.join("; ")}`);
  evidence.push({ engine, status: "pass", javascriptErrors: errors });
  await browser.close();
  console.log(`${engine}: passed`);
}
writeFileSync(
  "artifacts/browser/admin-results.json",
  JSON.stringify(evidence, null, 2),
);
