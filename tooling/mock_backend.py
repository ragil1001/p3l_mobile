#!/usr/bin/env python3

import base64
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

HOST = "0.0.0.0"
PORT = 8000

PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAIAAAD/gAIDAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAJElEQVR4nO3BMQEAAADCoPVPbQ0PoAAAAAAAAAAAAAAAAAAAgKcBnAAB7j3JggAAAABJRU5ErkJggg=="
)

PRODUCTS = [
    {
        "id": "BRG001",
        "name": "Kamera Mirrorless Sony",
        "price": 4750000,
        "image": "/api/placeholder/60/60",
    },
    {
        "id": "BRG002",
        "name": "Kursi Kerja Ergonomis",
        "price": 850000,
        "image": "/api/placeholder/60/60",
    },
    {
        "id": "BRG003",
        "name": "Gitar Akustik",
        "price": 1200000,
        "image": "/api/placeholder/60/60",
    },
    {
        "id": "BRG004",
        "name": "Set Buku Pemrograman",
        "price": 325000,
        "image": "/api/placeholder/60/60",
    },
]

CATEGORIES = [
    {"NAMA": "Elektronik & Gadget"},
    {"NAMA": "Perabotan Rumah Tangga"},
    {"NAMA": "Pakaian & Aksesori"},
    {"NAMA": "Buku, Alat Tulis, & Peralatan Sekolah"},
    {"NAMA": "Hobi, Mainan, & Koleksi"},
    {"NAMA": "Otomotif & Aksesori"},
]


class Handler(BaseHTTPRequestHandler):
    server_version = "ReuseMartCapture/1.0"

    def log_message(self, format_string, *args):
        print(f"{self.address_string()} - {format_string % args}", flush=True)

    def _json(self, payload, status=200):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _png(self):
        self.send_response(200)
        self.send_header("Content-Type", "image/png")
        self.send_header("Content-Length", str(len(PNG)))
        self.end_headers()
        self.wfile.write(PNG)

    def do_GET(self):
        path = urlparse(self.path).path

        if path == "/health":
            self._json({"ok": True})
            return

        if path.endswith("/thumbnail") or "/placeholder/" in path:
            self._png()
            return

        if path == "/api/categories":
            self._json(CATEGORIES)
            return

        if path == "/api/products/mobile":
            self._json({"success": True, "data": PRODUCTS})
            return

        if path == "/api/auth/profile":
            role_header = self.headers.get("X-Capture-Role", "")
            if role_header == "kurir":
                role = ["kurir"]
                name = "Dimas Pratama"
            else:
                role = ["hunter", "kurir"]
                name = "Raka Wibowo"
            self._json(
                {
                    "user_type": "pegawai",
                    "user": {"nama": name, "role": role},
                }
            )
            return

        if path == "/api/hunter/komisi":
            self._json(
                [
                    {"KOMISI_HUNTER": 350000},
                    {"KOMISI_HUNTER": 225000},
                    {"KOMISI_HUNTER": 180000},
                ]
            )
            return

        if path == "/api/hunter/barang-titipan":
            self._json(
                {
                    "data": [
                        {
                            "KODE_PRODUK": "BRG001",
                            "product_name": "Kamera Mirrorless Sony",
                            "penitip_name": "Nadia Putri",
                            "consignment_date": "2026-07-15",
                            "status": "Terjual",
                            "product_image": "/api/placeholder/60/60",
                        },
                        {
                            "KODE_PRODUK": "BRG005",
                            "product_name": "Laptop Lenovo ThinkPad",
                            "penitip_name": "Budi Santoso",
                            "consignment_date": "2026-07-22",
                            "status": "Tersedia",
                            "product_image": "/api/placeholder/60/60",
                        },
                        {
                            "KODE_PRODUK": "BRG008",
                            "product_name": "Sepeda Lipat",
                            "penitip_name": "Sari Dewi",
                            "consignment_date": "2026-08-01",
                            "status": "Tersedia",
                            "product_image": "/api/placeholder/60/60",
                        },
                    ]
                }
            )
            return

        if path == "/api/kurir/transaksi-penjualan":
            self._json(
                {
                    "data": [
                        {
                            "id_penjualan": 31,
                            "no_nota": "NOTA-2026-081",
                            "status": "Siap Dikirim",
                            "tanggal_transaksi": "2026-08-05",
                        },
                        {
                            "id_penjualan": 29,
                            "no_nota": "NOTA-2026-076",
                            "status": "Sedang Dikirim",
                            "tanggal_transaksi": "2026-08-04",
                        },
                        {
                            "id_penjualan": 22,
                            "no_nota": "NOTA-2026-061",
                            "status": "Sudah Diterima",
                            "tanggal_transaksi": "2026-08-01",
                        },
                    ]
                }
            )
            return

        if path.startswith("/api/kurir/transaksi-penjualan/"):
            self._json(
                {
                    "data": {
                        "nama_pembeli": "Alya Ramadhani",
                        "alamat": "Jl. Kaliurang KM 7, Sleman, Yogyakarta",
                        "products": [
                            {
                                "product_id": "BRG001",
                                "nama_barang": "Kamera Mirrorless Sony",
                                "harga_barang": "Rp4.750.000",
                                "image": "/api/placeholder/60/60",
                            }
                        ],
                    }
                }
            )
            return

        self._json({"success": True, "data": []})

    def do_POST(self):
        self._json({"success": True, "message": "capture-only response"})

    def do_PUT(self):
        self._json({"success": True, "message": "capture-only response"})


if __name__ == "__main__":
    print(f"Mock backend listening on http://{HOST}:{PORT}", flush=True)
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
