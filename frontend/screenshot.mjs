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

  // Form page
  await page.goto('http://localhost:3000/', { waitUntil: 'networkidle' })
  await page.waitForSelector('.form-card')
  await page.screenshot({
    path: path.join(__dirname, 'screenshots', 'form-desktop.png'),
    fullPage: true,
  })
  console.log('form-desktop.png saved')

  // Mobile form
  await page.setViewportSize({ width: 375, height: 667 })
  await page.waitForTimeout(300)
  await page.screenshot({
    path: path.join(__dirname, 'screenshots', 'form-mobile.png'),
    fullPage: true,
  })
  console.log('form-mobile.png saved')

  // Thank-you page - need to navigate via form submit or directly with state
  // Let's go direct with state using history API
  await page.setViewportSize({ width: 1280, height: 720 })
  await page.goto('http://localhost:3000/thank-you', { waitUntil: 'networkidle' })
  // The thank-you page reads from location.state which will be empty
  // Let's inject a fake state to see the full layout
  await page.evaluate(() => {
    history.replaceState({
      response: '**Answer:** To reset your password, go to the login page and click "Forgot password". You will receive an email with a reset link that expires in 1 hour.\n\nIf you don\'t see the email, check your spam folder or contact support.',
      userName: 'Jordan'
    }, '', '/thank-you')
  })
  await page.reload({ waitUntil: 'networkidle' })
  await page.waitForSelector('.thankyou-card')
  await page.screenshot({
    path: path.join(__dirname, 'screenshots', 'thankyou-desktop.png'),
    fullPage: true,
  })
  console.log('thankyou-desktop.png saved')

  await page.setViewportSize({ width: 375, height: 667 })
  await page.waitForTimeout(300)
  await page.screenshot({
    path: path.join(__dirname, 'screenshots', 'thankyou-mobile.png'),
    fullPage: true,
  })
  console.log('thankyou-mobile.png saved')

  // Focus state - tab to first field
  await page.setViewportSize({ width: 1280, height: 720 })
  await page.goto('http://localhost:3000/', { waitUntil: 'networkidle' })
  await page.keyboard.press('Tab')
  await page.waitForTimeout(200)
  await page.screenshot({
    path: path.join(__dirname, 'screenshots', 'form-focus.png'),
    fullPage: true,
  })
  console.log('form-focus.png saved')

  // Error state - submit empty form
  await page.click('.btn-primary')
  await page.waitForTimeout(500)
  await page.screenshot({
    path: path.join(__dirname, 'screenshots', 'form-errors.png'),
    fullPage: true,
  })
  console.log('form-errors.png saved')

  await browser.close()
  console.log('All screenshots done')
}

run().catch(err => {
  console.error(err)
  process.exit(1)
})
