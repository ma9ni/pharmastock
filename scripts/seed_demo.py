#!/usr/bin/env python3
import argparse
import json
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta
from pathlib import Path

DEMO_EMAIL = "demo@erp.local"
DEMO_PASSWORD = "Demo@2026"


def request_json(method: str, url: str, body=None, token: str | None = None):
    data = json.dumps(body).encode("utf-8") if body is not None else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=30) as resp:
        raw = resp.read().decode("utf-8")
        return json.loads(raw) if raw.strip() else None


def demo_payload() -> dict:
    now = datetime.now()
    def expiry(days: int) -> str:
        return (now + timedelta(days=days)).date().isoformat()

    return {
        "users": [
            {
                "email": DEMO_EMAIL,
                "password": DEMO_PASSWORD,
                "fullName": "Demo Manager",
                "phoneNumber": "+33000000000",
                "role": "admin",
            }
        ],
        "categories": [
            "Medication",
            "Consumables",
            "Cold Chain",
            "Antibiotics",
            "Diagnostics",
            "Emergency",
            "PPE",
        ],
        "products": [
            {"id": 1, "materialName": "Paracetamol 500mg", "materialSKU": "MED-PARA-500", "quantity": 420, "unit": "boxes", "logNumber": "LOT-PARA-2026-A", "expiryDate": expiry(420), "supplier": "Atlas Pharma", "minStockLevel": 80, "isAvailable": True, "categoryId": 1, "categoryName": "Medication"},
            {"id": 2, "materialName": "Sterile Syringes 5ml", "materialSKU": "MED-SYR-005", "quantity": 95, "unit": "packs", "logNumber": "LOT-SYR-2026-B", "expiryDate": expiry(700), "supplier": "NeoMedical Supplies", "minStockLevel": 120, "isAvailable": True, "categoryId": 2, "categoryName": "Consumables"},
            {"id": 3, "materialName": "Nitrile Gloves M", "materialSKU": "MED-GLV-M", "quantity": 38, "unit": "cartons", "logNumber": "LOT-GLV-2026-C", "expiryDate": expiry(900), "supplier": "SafeCare Distribution", "minStockLevel": 50, "isAvailable": True, "categoryId": 2, "categoryName": "Consumables"},
            {"id": 4, "materialName": "Insulin Cool Packs", "materialSKU": "MED-COOL-INS", "quantity": 18, "unit": "units", "logNumber": "LOT-COOL-2026-D", "expiryDate": expiry(120), "supplier": "ColdChain Health", "minStockLevel": 20, "isAvailable": True, "categoryId": 3, "categoryName": "Cold Chain"},
            {"id": 5, "materialName": "Amoxicillin 1g", "materialSKU": "MED-AMOX-1G", "quantity": 185, "unit": "boxes", "logNumber": "LOT-AMOX-2026-E", "expiryDate": expiry(240), "supplier": "EuroGenerics", "minStockLevel": 60, "isAvailable": True, "categoryId": 4, "categoryName": "Antibiotics"},
            {"id": 6, "materialName": "Azithromycin 500mg", "materialSKU": "MED-AZIT-500", "quantity": 22, "unit": "boxes", "logNumber": "LOT-AZIT-2026-F", "expiryDate": expiry(32), "supplier": "EuroGenerics", "minStockLevel": 40, "isAvailable": True, "categoryId": 4, "categoryName": "Antibiotics"},
            {"id": 7, "materialName": "Rapid Glucose Tests", "materialSKU": "DIA-GLU-RAPID", "quantity": 310, "unit": "kits", "logNumber": "LOT-GLU-2026-G", "expiryDate": expiry(420), "supplier": "DiagnoCare", "minStockLevel": 80, "isAvailable": True, "categoryId": 5, "categoryName": "Diagnostics"},
            {"id": 8, "materialName": "COVID Antigen Tests", "materialSKU": "DIA-COV-AG", "quantity": 64, "unit": "kits", "logNumber": "LOT-COV-2026-H", "expiryDate": expiry(21), "supplier": "DiagnoCare", "minStockLevel": 50, "isAvailable": True, "categoryId": 5, "categoryName": "Diagnostics"},
            {"id": 9, "materialName": "Adrenaline 1mg/ml", "materialSKU": "EMR-ADREN-1ML", "quantity": 8, "unit": "ampoules", "logNumber": "LOT-ADR-2026-I", "expiryDate": expiry(65), "supplier": "Urgence Pharma", "minStockLevel": 30, "isAvailable": True, "categoryId": 6, "categoryName": "Emergency"},
            {"id": 10, "materialName": "Saline Solution 0.9%", "materialSKU": "EMR-SAL-500", "quantity": 144, "unit": "bottles", "logNumber": "LOT-SAL-2026-J", "expiryDate": expiry(510), "supplier": "MedFluid", "minStockLevel": 90, "isAvailable": True, "categoryId": 6, "categoryName": "Emergency"},
            {"id": 11, "materialName": "FFP2 Masks", "materialSKU": "PPE-MASK-FFP2", "quantity": 520, "unit": "boxes", "logNumber": "LOT-MASK-2026-K", "expiryDate": expiry(900), "supplier": "SafeCare Distribution", "minStockLevel": 150, "isAvailable": True, "categoryId": 7, "categoryName": "PPE"},
            {"id": 12, "materialName": "Surgical Gowns L", "materialSKU": "PPE-GOWN-L", "quantity": 46, "unit": "cartons", "logNumber": "LOT-GOWN-2026-L", "expiryDate": expiry(720), "supplier": "SafeCare Distribution", "minStockLevel": 45, "isAvailable": True, "categoryId": 7, "categoryName": "PPE"},
            {"id": 13, "materialName": "Insulin Glargine Pens", "materialSKU": "COLD-INS-GLAR", "quantity": 26, "unit": "pens", "logNumber": "LOT-GLAR-2026-M", "expiryDate": expiry(18), "supplier": "ColdChain Health", "minStockLevel": 35, "isAvailable": True, "categoryId": 3, "categoryName": "Cold Chain"},
            {"id": 14, "materialName": "Vaccine Carrier 5L", "materialSKU": "COLD-CARR-5L", "quantity": 11, "unit": "units", "logNumber": "LOT-CARR-2026-N", "expiryDate": expiry(1100), "supplier": "ColdChain Health", "minStockLevel": 10, "isAvailable": True, "categoryId": 3, "categoryName": "Cold Chain"},
            {"id": 15, "materialName": "Blood Pressure Monitors", "materialSKU": "DIA-BP-MON", "quantity": 17, "unit": "units", "logNumber": "LOT-BPM-2026-O", "expiryDate": expiry(1400), "supplier": "MedTech Pro", "minStockLevel": 12, "isAvailable": True, "categoryId": 5, "categoryName": "Diagnostics"},
            {"id": 16, "materialName": "Ibuprofen 400mg", "materialSKU": "MED-IBU-400", "quantity": 210, "unit": "boxes", "logNumber": "LOT-IBU-2026-P", "expiryDate": expiry(390), "supplier": "Atlas Pharma", "minStockLevel": 70, "isAvailable": True, "categoryId": 1, "categoryName": "Medication"},
            {"id": 17, "materialName": "Alcohol Swabs", "materialSKU": "CON-SWAB-ALC", "quantity": 72, "unit": "packs", "logNumber": "LOT-SWAB-2026-Q", "expiryDate": expiry(27), "supplier": "NeoMedical Supplies", "minStockLevel": 100, "isAvailable": True, "categoryId": 2, "categoryName": "Consumables"},
            {"id": 18, "materialName": "Morphine 10mg/ml", "materialSKU": "EMR-MORPH-10", "quantity": 0, "unit": "ampoules", "logNumber": "LOT-MOR-2026-R", "expiryDate": expiry(75), "supplier": "Urgence Pharma", "minStockLevel": 15, "isAvailable": False, "categoryId": 6, "categoryName": "Emergency"},
        ],
        "orders": [
            {"id": "PH-PO-2026-001", "productId": 1, "productName": "Paracetamol 500mg", "productSku": "MED-PARA-500", "quantity": 120, "unit": "boxes", "logNumber": "LOT-PARA-2026-A", "categoryId": 1, "type": "add", "status": "completed", "supplier": "Atlas Pharma", "createdBy": "Demo Manager", "invoiceNumber": "PH-PO-2026-001", "createdAt": (now - timedelta(days=7)).isoformat(), "notes": "Initial replenishment after monthly inventory count."},
            {"id": "PH-DSP-2026-014", "productId": 2, "productName": "Sterile Syringes 5ml", "productSku": "MED-SYR-005", "quantity": 35, "unit": "packs", "logNumber": "LOT-SYR-2026-B", "categoryId": 2, "type": "export", "status": "completed", "recipient": "Central Clinic", "createdBy": "Demo Manager", "invoiceNumber": "PH-DSP-2026-014", "createdAt": (now - timedelta(days=2)).isoformat(), "notes": "Routine dispatch for outpatient care unit."},
            {"id": "PH-PO-2026-002", "productId": 5, "productName": "Amoxicillin 1g", "productSku": "MED-AMOX-1G", "quantity": 90, "unit": "boxes", "logNumber": "LOT-AMOX-2026-E", "categoryId": 4, "type": "add", "status": "completed", "supplier": "EuroGenerics", "createdBy": "Demo Manager", "invoiceNumber": "PH-PO-2026-002", "createdAt": (now - timedelta(days=12)).isoformat(), "notes": "Supplier delivery received and checked."},
            {"id": "PH-REQ-2026-021", "productId": 13, "productName": "Insulin Glargine Pens", "productSku": "COLD-INS-GLAR", "quantity": 18, "unit": "pens", "logNumber": "LOT-GLAR-2026-M", "categoryId": 3, "type": "export", "status": "completed", "recipient": "Endocrinology Ward", "createdBy": "Demo Manager", "invoiceNumber": "PH-REQ-2026-021", "expiryDate": expiry(18), "createdAt": (now - timedelta(days=1)).isoformat(), "notes": "Cold-chain dispatch with expiry control."},
            {"id": "PH-REQ-2026-022", "productId": 9, "productName": "Adrenaline 1mg/ml", "productSku": "EMR-ADREN-1ML", "quantity": 10, "unit": "ampoules", "logNumber": "LOT-ADR-2026-I", "categoryId": 6, "type": "export", "status": "pending", "recipient": "Emergency Department", "createdBy": "Demo Manager", "invoiceNumber": "PH-REQ-2026-022", "createdAt": (now - timedelta(hours=6)).isoformat(), "notes": "Pending approval because current stock is below threshold."},
            {"id": "PH-PO-2026-003", "productId": 18, "productName": "Morphine 10mg/ml", "productSku": "EMR-MORPH-10", "quantity": 40, "unit": "ampoules", "logNumber": "LOT-MOR-2026-S", "categoryId": 6, "type": "add", "status": "pending", "supplier": "Urgence Pharma", "createdBy": "Demo Manager", "invoiceNumber": "PH-PO-2026-003", "createdAt": (now - timedelta(hours=3)).isoformat(), "notes": "Controlled product replenishment awaiting pharmacist validation."},
            {"id": "PH-DISP-2026-004", "productId": 8, "productName": "COVID Antigen Tests", "productSku": "DIA-COV-AG", "quantity": 12, "unit": "kits", "logNumber": "LOT-COV-2026-H", "categoryId": 5, "type": "disposal", "status": "completed", "recipient": "Quality Control", "createdBy": "Demo Manager", "invoiceNumber": "PH-DISP-2026-004", "expiryDate": expiry(21), "createdAt": (now - timedelta(days=4)).isoformat(), "notes": "Damaged packaging removed from available stock."},
            {"id": "PH-ADJ-2026-005", "productId": 17, "productName": "Alcohol Swabs", "productSku": "CON-SWAB-ALC", "quantity": 20, "unit": "packs", "logNumber": "LOT-SWAB-2026-Q", "categoryId": 2, "type": "edit", "status": "completed", "createdBy": "Demo Manager", "invoiceNumber": "PH-ADJ-2026-005", "expiryDate": expiry(27), "createdAt": (now - timedelta(days=3)).isoformat(), "notes": "Stock correction after cycle count."},
            {"id": "PH-REQ-2026-023", "productId": 11, "productName": "FFP2 Masks", "productSku": "PPE-MASK-FFP2", "quantity": 75, "unit": "boxes", "logNumber": "LOT-MASK-2026-K", "categoryId": 7, "type": "export", "status": "completed", "recipient": "Surgery Department", "createdBy": "Demo Manager", "invoiceNumber": "PH-REQ-2026-023", "createdAt": (now - timedelta(days=5)).isoformat(), "notes": "Weekly PPE allocation."},
            {"id": "PH-PO-2026-004", "productId": 7, "productName": "Rapid Glucose Tests", "productSku": "DIA-GLU-RAPID", "quantity": 160, "unit": "kits", "logNumber": "LOT-GLU-2026-G", "categoryId": 5, "type": "add", "status": "completed", "supplier": "DiagnoCare", "createdBy": "Demo Manager", "invoiceNumber": "PH-PO-2026-004", "createdAt": (now - timedelta(days=15)).isoformat(), "notes": "Bulk purchase for diabetes screening campaign."},
            {"id": "PH-REQ-2026-024", "productId": 6, "productName": "Azithromycin 500mg", "productSku": "MED-AZIT-500", "quantity": 16, "unit": "boxes", "logNumber": "LOT-AZIT-2026-F", "categoryId": 4, "type": "export", "status": "canceled", "recipient": "Pediatrics Ward", "createdBy": "Demo Manager", "invoiceNumber": "PH-REQ-2026-024", "expiryDate": expiry(32), "createdAt": (now - timedelta(days=9)).isoformat(), "notes": "Canceled after therapeutic substitution."},
        ],
    }


def write_payload(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(demo_payload(), indent=2), encoding="utf-8")


def seed_api(base_url: str) -> None:
    payload = demo_payload()
    try:
        request_json("POST", f"{base_url}/Auth/register/admin", payload["users"][0])
    except urllib.error.HTTPError as exc:
        if exc.code not in (400, 409):
            raise
    auth = request_json("POST", f"{base_url}/Auth/login", {"email": DEMO_EMAIL, "password": DEMO_PASSWORD})
    token = (auth or {}).get("token") or (auth or {}).get("accessToken") or ((auth or {}).get("data") or {}).get("token")
    if not token:
        raise RuntimeError("Login succeeded but no token was returned.")
    for category in payload["categories"]:
        try:
            request_json("POST", f"{base_url}/Categories", {"name": category}, token)
        except urllib.error.HTTPError as exc:
            if exc.code not in (400, 409):
                raise
    for product in payload["products"]:
        try:
            request_json("POST", f"{base_url}/Products", product, token)
        except urllib.error.HTTPError as exc:
            if exc.code not in (400, 409):
                raise
    for order in payload["orders"]:
        try:
            request_json("POST", f"{base_url}/Orders", order, token)
        except urllib.error.HTTPError as exc:
            if exc.code not in (400, 409):
                raise


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed Pharmacy WMS backend, or export a demo seed JSON if backend is unavailable.")
    parser.add_argument("--base-url", default="https://pharmacy-wms-backend.onrender.com/api")
    parser.add_argument("--json", type=Path, default=Path(__file__).resolve().parents[1] / "demo_seed" / "pharmacy_wms_demo_seed.json")
    parser.add_argument("--api", action="store_true", help="Try to seed the backend API.")
    args = parser.parse_args()
    write_payload(args.json)
    print(f"Wrote demo payload: {args.json}")
    print(f"Login convention: {DEMO_EMAIL} / {DEMO_PASSWORD}")
    if args.api:
        try:
            seed_api(args.base_url.rstrip("/"))
            print(f"Seeded Pharmacy WMS API: {args.base_url}")
        except Exception as exc:
            print(f"API seed failed: {exc}", file=sys.stderr)
            print("The Render backend may be suspended or API auth may need configuration.", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
