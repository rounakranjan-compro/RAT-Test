import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('http://localhost:5173/');
  await page.getByRole('button', { name: 'Continue with Google' }).click();
  await page.getByRole('textbox', { name: 'Email or phone' }).fill('rounak.ranjan@comprotechnologies.com');
  await page.getByRole('textbox', { name: 'Email or phone' }).press('Enter');
  await page.getByRole('textbox', { name: 'Enter your password' }).press('CapsLock');
  await page.getByRole('textbox', { name: 'Enter your password' }).fill('R');
  await page.getByRole('textbox', { name: 'Enter your password' }).press('CapsLock');
  await page.getByRole('textbox', { name: 'Enter your password' }).fill('Rounak@2025');
  await page.getByRole('textbox', { name: 'Enter your password' }).press('Enter');
  await page.goto('https://accounts.google.com/signin/oauth/id?authuser=0&part=AJi8hANMk6QRjn6sMO1hd7V-K7x1y1cdge68Qw14OF4r7Fl5QxBQO2c_vGCFdwztBZkpIoqvAYw6GGa22VAXmjCM_RCtwth9RqXpmD6oDr2quzqlUtgTE0iK-lm8JTPh3g0Bg6ji54jo3kPlxg_MbCjieVaMcoiDDnXnzclrSINF1qzCzhQAlp58AyNjxt6RUQHxmF9DVdzv--oOwxX79LJPm9tNxygO5r3BdfyMQ-hwQo5_-O6g5yIVUq-TOrBYe6082ckFo3nZyHBGvbckX7c8VuDtN9lz7nlOpJmF8fYYpN8T66pIVrtu2vBRjBTbilgShjEMbYMImHD02ZqzCRbV1qKvE-NZj8viM0DBymeCSk8CL0UB3A1gCe0gXMJ6I6vEowfU6XXXpbF76lk_KuIt7Scd8Bmv0pp9L3YjvIj3EH1V2VMsSJvGPcWUVVXz_zvf2rCvne7u2fM4eeEGdgUkmnLH24oyPKJK7Q7TrIxImqRlUMWOWJPI0b-ct3N-DEZqDmsy6rR5Yak-Y4aPPnfzujshxPrZ9k0fdK9a1HKG4z-4G9ni9ahy6A83EY4V8FkI1CBXtq7bcmyp32HUiDj1Q1qhj-vKUKtvctNdSeQP0S7UuBRK8ht1plwujvd0a9mymkbnyte9twxQM-Ly8zQXO3no96If0ZjEG9Bfx_7kfbDKKisQV9rIVkiFdGiEiv4k__zYnEiB-boZ3EnFnjunc1pX6V68tVJ4GbLn8dyaHC0vot8akq503hSsiaFObJcpblkKbWxj6f05CwGAnXDsgFR-9qzwgrlUBEPBnUJYN9rpwIeSidzh-EzCuGoyw3Ggcq4mZJoq1jWQWP6WRIA6ThnikXHlXZ55tiCnkkUkxNirvStFn8QKPOagpCjr9JCf6jmxGDCzrdVY7SvqOWaHAqSv8FT_dOY4niHEr899Q3zXHo_zrGVmJcqF0Yq0IxYRkyQ43xgWoPKNWi7Ss_9JsNMVuzNadiICP7Gq69dCZSuyrhqVxkY&flowName=GeneralOAuthFlow&as=S-1592123463%3A1781587566210376&client_id=106146195434-3fuohld8ffe9vessjo6d0d0mcna7caki.apps.googleusercontent.com&rapt=AEjHL4PnT3G-aJSDYiWKByxuR0_fSMf6QNWaKVUGE5CdmHoD6sSTnnBjI8K25OArfzTPG7Oq1ML3iOZXEhLRzt85Flmd2cICduCf9fFmfIL9Gd1iLZVIcpA#');
  await page.getByRole('button', { name: 'Continue' }).click();
  await page1.goto('http://localhost:5173/');
});