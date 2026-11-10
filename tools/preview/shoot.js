// node tools/preview/shoot.js parts.json outDir  -> renders a few camera views to PNG
const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");
const [, , partsFile, outDir] = process.argv;
const views = {
  base_overview: { pos: [0, 170, 300], look: [0, 0, 40], fov: 50 },
  base_close: { pos: [-60, 45, 190], look: [-40, 8, 110], fov: 55 },
  meadow_overview: { pos: [0, 170, -20], look: [0, 0, -280], fov: 50 },
  meadow_close: { pos: [-20, 40, -150], look: [-40, 14, -225], fov: 60 },
  meadow_trees: { pos: [90, 30, -150], look: [110, 20, -215], fov: 60 },
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
