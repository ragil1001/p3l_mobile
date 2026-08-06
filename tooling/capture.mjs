import puppeteer from 'puppeteer-core';
import { execSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';

const executablePath = execSync(
  'command -v google-chrome-stable || command -v google-chrome || command -v chromium-browser || command -v chromium',
  { encoding: 'utf8' }
).trim();

const browser = await puppeteer.launch({
  executablePath,
  headless: true,
  args: [
    '--no-sandbox',
    '--disable-dev-shm-usage',
    '--disable-web-security',
    '--enable-webgl',
    '--use-gl=swiftshader'
  ]
});

const tinyPng = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAIAAAD/gAIDAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAJElEQVR4nO3BMQEAAADCoPVPbQ0PoAAAAAAAAAAAAAAAAAAAgKcBnAAB7j3JggAAAABJRU5ErkJggg==',
  'base64'
);

const products = [
  { id: 'BRG001', name: 'Kamera Mirrorless Sony', price: 4750000, image: '/api/placeholder/60/60' },
  { id: 'BRG002', name: 'Kursi Kerja Ergonomis', price: 850000, image: '/api/placeholder/60/60' },
  { id: 'BRG003', name: 'Gitar Akustik', price: 1200000, image: '/api/placeholder/60/60' },
  { id: 'BRG004', name: 'Set Buku Pemrograman', price: 325000, image: '/api/placeholder/60/60' }
];

const categories = [
  { NAMA: 'Elektronik & Gadget' },
  { NAMA: 'Perabotan Rumah Tangga' },
  { NAMA: 'Pakaian & Aksesori' },
  { NAMA: 'Buku, Alat Tulis, & Peralatan Sekolah' },
  { NAMA: 'Hobi, Mainan, & Koleksi' },
  { NAMA: 'Otomotif & Aksesori' }
];

function apiPayload(path, screen) {
  if (path.endsWith('/categories')) return categories;
  if (path.endsWith('/products/mobile')) return { success: true, data: products };
  if (path.endsWith('/auth/profile')) {
    if (screen === 'kurir') {
      return { user_type: 'pegawai', user: { nama: 'Dimas Pratama', role: ['kurir'] } };
    }
    return { user_type: 'pegawai', user: { nama: 'Raka Wibowo', role: ['hunter'] } };
  }
  if (path.endsWith('/hunter/komisi')) {
    return [
      { KOMISI_HUNTER: 350000 },
      { KOMISI_HUNTER: 225000 },
      { KOMISI_HUNTER: 180000 }
    ];
  }
  if (path.endsWith('/hunter/barang-titipan')) {
    return {
      data: [
        {
          KODE_PRODUK: 'BRG001',
          product_name: 'Kamera Mirrorless Sony',
          penitip_name: 'Nadia Putri',
          consignment_date: '2026-07-15',
          status: 'Terjual',
          product_image: '/api/placeholder/60/60'
        },
        {
          KODE_PRODUK: 'BRG005',
          product_name: 'Laptop Lenovo ThinkPad',
          penitip_name: 'Budi Santoso',
          consignment_date: '2026-07-22',
          status: 'Tersedia',
          product_image: '/api/placeholder/60/60'
        },
        {
          KODE_PRODUK: 'BRG008',
          product_name: 'Sepeda Lipat',
          penitip_name: 'Sari Dewi',
          consignment_date: '2026-08-01',
          status: 'Tersedia',
          product_image: '/api/placeholder/60/60'
        }
      ]
    };
  }
  if (path.endsWith('/kurir/transaksi-penjualan')) {
    return {
      data: [
        { id_penjualan: 31, no_nota: 'NOTA-2026-081', status: 'Siap Dikirim', tanggal_transaksi: '2026-08-05' },
        { id_penjualan: 29, no_nota: 'NOTA-2026-076', status: 'Sedang Dikirim', tanggal_transaksi: '2026-08-04' },
        { id_penjualan: 22, no_nota: 'NOTA-2026-061', status: 'Sudah Diterima', tanggal_transaksi: '2026-08-01' }
      ]
    };
  }
  if (path.includes('/kurir/transaksi-penjualan/')) {
    return {
      data: {
        nama_pembeli: 'Alya Ramadhani',
        alamat: 'Jl. Kaliurang KM 7, Sleman, Yogyakarta',
        products: [
          {
            product_id: 'BRG001',
            nama_barang: 'Kamera Mirrorless Sony',
            harga_barang: 'Rp4.750.000',
            image: '/api/placeholder/60/60'
          }
        ]
      }
    };
  }
  return { success: true, data: [] };
}

const summary = {};

async function capture(name, screen, viewport, waitMs) {
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => {
    if (message.type() === 'error') errors.push(message.text());
  });

  await page.setRequestInterception(true);
  page.on('request', request => {
    const url = request.url();
    if (!url.startsWith('http://10.0.2.2:8000/api/')) {
      request.continue();
      return;
    }

    const path = new URL(url).pathname;
    if (path.endsWith('/thumbnail') || path.includes('/placeholder/')) {
      request.respond({ status: 200, contentType: 'image/png', body: tinyPng });
      return;
    }

    request.respond({
      status: 200,
      contentType: 'application/json',
      headers: { 'Access-Control-Allow-Origin': '*' },
      body: JSON.stringify(apiPayload(path, screen))
    });
  });

  await page.setViewport(viewport);
  await page.goto(`http://127.0.0.1:4174/?screen=${screen}`, {
    waitUntil: 'networkidle2',
    timeout: 120000
  });
  await page.waitForSelector('flt-glass-pane, flutter-view', { timeout: 60000 });
  await new Promise(resolve => setTimeout(resolve, waitMs));

  const file = `runtime/screenshots/${name}.png`;
  await page.screenshot({ path: file, fullPage: false });
  summary[name] = {
    url: page.url(),
    canvasCount: await page.evaluate(() => document.querySelectorAll('canvas').length),
    flutterViews: await page.evaluate(() => document.querySelectorAll('flt-glass-pane, flutter-view').length),
    errors
  };
  await page.close();
}

const mobile = { width: 430, height: 932, deviceScaleFactor: 1 };
const tablet = { width: 820, height: 1180, deviceScaleFactor: 1 };

await capture('p3l-login-mobile', 'login', mobile, 3500);
await capture('p3l-register-mobile', 'register', mobile, 3500);
await capture('p3l-pembeli-mobile', 'pembeli', mobile, 7000);
await capture('p3l-penitip-mobile', 'penitip', mobile, 4500);
await capture('p3l-hunter-mobile', 'hunter', mobile, 7000);
await capture('p3l-kurir-mobile', 'kurir', mobile, 7000);
await capture('p3l-pembeli-tablet', 'pembeli', tablet, 7000);

writeFileSync('runtime/page-summary.json', JSON.stringify(summary, null, 2));
await browser.close();
