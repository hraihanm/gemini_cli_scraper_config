const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const url = process.argv[2];
const outputPath = process.argv[3];
const action = process.argv[4]; // Optional action like "scroll" or "click_more"

if (!url || !outputPath) {
  console.error("Usage: node fetch_html.js <url> <outputPath> [action]");
  process.exit(1);
}

(async () => {
  console.log(`Launching browser for: ${url}`);
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
  });
  const page = await context.newPage();

  try {
    // Navigate
    await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 });
    console.log("Navigation successful.");

    // Dismiss cookie popup if it exists
    try {
      const cookieButton = page.locator('button:has-text("Godta")');
      if (await cookieButton.count() > 0 && await cookieButton.isVisible()) {
        console.log("Clicking cookie accept button...");
        await cookieButton.click();
        await page.waitForTimeout(2000);
      }
    } catch (e) {
      console.log("No cookie banner found or error clicking: " + e.message);
    }

    if (action === "click_more") {
      console.log("Attempting to click 'Vis flere' load-more buttons...");
      let limit = 25;
      while (limit > 0) {
        const button = page.locator('.ws-product-view__footer button.ngr-button');
        if (await button.count() === 0 || !await button.isVisible()) {
          console.log("No more load-more button found.");
          break;
        }
        try {
          console.log(`Clicking 'Vis flere' (limit remaining: ${limit})...`);
          await button.click();
          await page.waitForTimeout(2000);
        } catch (e) {
          console.log("Click failed or ended: " + e.message);
          break;
        }
        limit--;
      }
    }

    // Wait a bit for everything to settle
    await page.waitForTimeout(2000);

    // Save HTML content
    const html = await page.content();
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, html, 'utf8');
    console.log(`Successfully saved HTML to ${outputPath} (${html.length} chars)`);
  } catch (err) {
    console.error(`Error fetching page: ${err.message}`);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
