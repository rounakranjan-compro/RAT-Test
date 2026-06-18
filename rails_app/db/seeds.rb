# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Create scripts first (Tests require scripts)
login_script = Script.create!(
  name: 'login.spec.js',
  raw_content: %(import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('https://www.writeyournote.com/auth/login');
  await page.getByRole('textbox', { name: 'Email' }).click();
  await page.getByRole('textbox', { name: 'Email' }).fill('student5@mailsac.com');
  await page.getByRole('textbox', { name: 'Password' }).click();
  await page.getByRole('textbox', { name: 'Password' }).fill('Compro111');
  await page.getByRole('button', { name: 'Log In' }).click();
  await page.getByRole('textbox', { name: 'Search' }).click();
});),
  normalized_content: %(import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('https://www.writeyournote.com/auth/login');
  await page.getByRole('textbox', { name: 'Email' }).click();
  await page.getByRole('textbox', { name: 'Email' }).fill('student5@mailsac.com');
  await page.getByRole('textbox', { name: 'Password' }).click();
  await page.getByRole('textbox', { name: 'Password' }).fill('Compro111');
  await page.getByRole('button', { name: 'Log In' }).click();
  await page.getByRole('textbox', { name: 'Search' }).click();
});),
  language: 'javascript'
)

navigation_script = Script.create!(
  name: 'navigation.spec.js',
  raw_content: %(import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('https://www.writeyournote.com/auth/login');
  await page.getByRole('textbox', { name: 'Email' }).click();
  await page.getByRole('textbox', { name: 'Email' }).fill('student5@mailsac.com');
  await page.getByRole('textbox', { name: 'Password' }).click();
  await page.getByRole('textbox', { name: 'Password' }).fill('Compro111');
  await page.getByRole('button', { name: 'Log In' }).click();
  await page.getByRole('textbox', { name: 'Search' }).click();
});),
  normalized_content: %(import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('https://www.writeyournote.com/auth/login');
  await page.getByRole('textbox', { name: 'Email' }).click();
  await page.getByRole('textbox', { name: 'Email' }).fill('student5@mailsac.com');
  await page.getByRole('textbox', { name: 'Password' }).click();
  await page.getByRole('textbox', { name: 'Password' }).fill('Compro111');
  await page.getByRole('button', { name: 'Log In' }).click();
  await page.getByRole('textbox', { name: 'Search' }).click();
});),
  language: 'javascript'
)

redeem_script = Script.create!(
  name: 'redeem_code.spec.js',
  raw_content: %(import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('https://www.writeyournote.com/auth/login');
  await page.getByRole('textbox', { name: 'Email' }).click();
  await page.getByRole('textbox', { name: 'Email' }).fill('student5@mailsac.com');
  await page.getByRole('textbox', { name: 'Password' }).click();
  await page.getByRole('textbox', { name: 'Password' }).fill('Compro11');
  await page.getByRole('button', { name: 'Log In' }).click();
  await page.getByRole('textbox', { name: 'Search' }).click();
});),
  normalized_content: %(import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('https://www.writeyournote.com/auth/login');
  await page.getByRole('textbox', { name: 'Email' }).click();
  await page.getByRole('textbox', { name: 'Email' }).fill('student5@mailsac.com');
  await page.getByRole('textbox', { name: 'Password' }).click();
  await page.getByRole('textbox', { name: 'Password' }).fill('Compro11');
  await page.getByRole('button', { name: 'Log In' }).click();
  await page.getByRole('textbox', { name: 'Search' }).click();
});),
  language: 'javascript'
)

puts "✅ Created #{Script.count} scripts"

# Create tests linked to scripts
Test.create!([
  {
    title: 'login',
    script: login_script
  },
  {
    title: 'navigation',
    script: navigation_script
  },
  {
    title: 'redeem_code',
    script: redeem_script
  }
])

puts "Created #{Test.count} tests"
puts "Seeding completed!"

