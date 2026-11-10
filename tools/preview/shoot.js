// node tools/preview/shoot.js parts.json outDir  -> renders a few camera views to PNG
const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");
const [, , partsFile, outDir] = process.argv;
const views = {
  base_overview: { pos: [0, 110, 150], look: [0, 0, -60], fov: 50 },
  base_trees: { pos: [-40, 30, 40], look: [-50, 18, -40], fov: 60 },
  base_walls: { pos: [70, 26, 30], look: [60, 14, -45], fov: 60 },
  meadow_overview: { pos: [0, 110, -120], look: [0, 0, -320], fov: 50 },
  meadow_trees: { pos: [-40, 30, -220], look: [-50, 18, -300], fov: 60 },
};
(async () => {
  const parts = fs.readFileSync(partsFile, "utf8");
  const browser = await chromium.launch({ args: ["--use-gl=angle", "--enable-unsafe-swiftshader"] });
  for (const [name, view] of Object.entries(views)) {
    const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
    page.on("console", (m) => m.type() === "error" && console.log(name, m.text()));
    page.on("pageerror", (e) => console.log(name, e.message));
    // Serve three.js from a local install if THREE_MODULE points at three.module.js (offline sandboxes).
    if (process.env.THREE_MODULE) {
      await page.route("https://unpkg.com/three@0.160.0/build/three.module.js", (r) =>
        r.fulfill({ contentType: "application/javascript", body: fs.readFileSync(process.env.THREE_MODULE) }));
    }
    await page.addInitScript(`window.PARTS=${parts};window.VIEW=${JSON.stringify(view)};`);
    await page.goto("file://" + path.resolve(__dirname, "render.html"));
    await page.waitForFunction("window.DONE === true", null, { timeout: 120000 });
    await page.screenshot({ path: path.join(outDir, name + ".png") });
    await page.close();
    console.log("rendered", name);
  }
  await browser.close();
})();
