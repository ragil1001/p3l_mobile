import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { PNG } from 'pngjs';

const results = {};
for (const name of readdirSync('runtime/screenshots').filter(file => file.endsWith('.png'))) {
  const png = PNG.sync.read(readFileSync(`runtime/screenshots/${name}`));
  const colors = new Set();
  let nonGrey = 0;
  for (let y = 0; y < png.height; y += 8) {
    for (let x = 0; x < png.width; x += 8) {
      const index = (png.width * y + x) * 4;
      const r = png.data[index];
      const g = png.data[index + 1];
      const b = png.data[index + 2];
      const a = png.data[index + 3];
      if (a < 20) continue;
      colors.add(`${Math.round(r / 8)},${Math.round(g / 8)},${Math.round(b / 8)}`);
      if (Math.max(r, g, b) - Math.min(r, g, b) > 12) nonGrey++;
    }
  }
  results[name] = {
    width: png.width,
    height: png.height,
    sampledColors: colors.size,
    nonGreySamples: nonGrey,
    visuallySuspicious: colors.size < 8 || nonGrey < 5
  };
}

writeFileSync('runtime/visual-validation.json', JSON.stringify(results, null, 2));
console.log(JSON.stringify(results, null, 2));
