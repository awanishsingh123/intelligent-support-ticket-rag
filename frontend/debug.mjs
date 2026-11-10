import { chromium } from 'playwright'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

async function run() {
  const browser = await chromium.launch({ headless: true })
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    deviceScaleFactor: 2,
  })
  const page = await context.newPage()

  // Debug: navigate with console logging
  page.on('console', msg => console.log('PAGE LOG:', msg.type(), msg.text()))
  page.on('pageerror', err => console.log('PAGE ERROR:', err.message))

  await page.goto('http://localhost:3000/', { waitUntil: 'networkidle', timeout: 15000 })
  await page.waitForTimeout(2000)
  
  const html = await page.content()
  console.log('=== PAGE HTML (first 2000 chars) ===')
  console.log(html.substring(0, 2000))

  await page.screenshot({
    path: path.join(__dirname, 'screenshots', 'debug-form.png'),
  })
  console.log('debug screenshot saved')

  await browser.close()
}

run().catch(err => {
  console.error('SCRIPT ERROR:', err)
  process.exit(1)
})
