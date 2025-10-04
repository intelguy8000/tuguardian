# Holiday Season Smishing Test Cases (December 2025)

## Test Case 1: Black Friday Fake Delivery
**Message:**
```
📦 DHL: Tu pedido de Black Friday está en camino. Rastreo: http://dhl-tracking-bf.xyz/pak123
Urgente: Confirma entrega hoy o será devuelto. Código: BF2025
```

**Expected Detection:**
- ✅ Entity: DHL (detected)
- ✅ Intent: URGENCY_PRESSURE ("urgente", "hoy", "será devuelto")
- ✅ Holiday Pattern: Black Friday
- ✅ Suspicious Link: `dhl-tracking-bf.xyz` (not `dhl.com`)
- ✅ Action: BLOCK_AND_SHOW_OFFICIAL
- ✅ Risk Level: DANGEROUS

---

## Test Case 2: MercadoLibre Payment Scam
**Message:**
```
MercadoLibre: Tu compra de $450.000 COP requiere verificación de pago.
Actualiza tu método de pago en: http://mercadolibre-secure.com/verify
Vence hoy. Pedido #ML-89234
```

**Expected Detection:**
- ✅ Entity: MercadoLibre (detected)
- ✅ Intent: FINANCIAL_ACTION ("pago", "actualiza")
- ✅ Intent: URGENCY_PRESSURE ("vence hoy")
- ✅ Suspicious Link: `mercadolibre-secure.com` (not `mercadolibre.com.co`)
- ✅ Action: BLOCK_AND_SHOW_OFFICIAL
- ✅ Risk Level: DANGEROUS

---

## Test Case 3: Nequi Fake Gift Card
**Message:**
```
🎁 FELICIDADES! Ganaste una tarjeta de regalo Nequi de $200.000 COP
por ser usuario frecuente. Reclama aquí: http://nequi-promo.co/claim
Solo por HOY - Navidad 2025
```

**Expected Detection:**
- ✅ Entity: Nequi (detected)
- ✅ Intent: PRIZE_CLAIM ("ganaste", "tarjeta de regalo", "reclama")
- ✅ Intent: URGENCY_PRESSURE ("solo por hoy")
- ✅ Holiday Pattern: Christmas ("navidad"), gift card ("tarjeta de regalo")
- ✅ Suspicious Link: `nequi-promo.co` (not `nequi.com.co`)
- ✅ Action: BLOCK_AND_SHOW_OFFICIAL
- ✅ Risk Level: DANGEROUS

---

## Test Case 4: Amazon Fake Tracking (Cyber Monday)
**Message:**
```
Amazon: Tu orden de Cyber Monday #CM-9823 no pudo ser entregada.
Actualiza tu dirección: http://amazon-delivery.net/update
Último día para cambios.
```

**Expected Detection:**
- ✅ Entity: Amazon (detected)
- ✅ Intent: INFORMATION_REQUEST ("actualiza tu dirección")
- ✅ Intent: URGENCY_PRESSURE ("último día")
- ✅ Holiday Pattern: Cyber Monday
- ✅ Suspicious Link: `amazon-delivery.net` (not `amazon.com`)
- ✅ Action: BLOCK_AND_SHOW_OFFICIAL
- ✅ Risk Level: DANGEROUS

---

## Test Case 5: Legitimate MercadoLibre (Should Pass)
**Message:**
```
MercadoLibre: Tu compra llegará mañana 🎉
Ver detalles: https://www.mercadolibre.com.co/compras/123456789
Código de rastreo: ML-2025-12345
```

**Expected Detection:**
- ✅ Entity: MercadoLibre (detected)
- ✅ Intent: NOTIFICATION_ONLY
- ✅ Official Link: `mercadolibre.com.co` (whitelisted)
- ✅ Action: ALLOW_SAFE
- ✅ Risk Level: SAFE

---

## Test Case 6: Fake Bancolombia Black Friday Promo
**Message:**
```
Bancolombia: Aprobamos tu crédito BLACK FRIDAY de $5.000.000 COP
URGENTE: Acepta antes de medianoche
Ingresa: http://bancolombia-credito.com/approve
```

**Expected Detection:**
- ✅ Entity: Bancolombia (detected)
- ✅ Intent: FINANCIAL_ACTION ("crédito", "acepta")
- ✅ Intent: URGENCY_PRESSURE ("urgente", "antes de medianoche")
- ✅ Holiday Pattern: Black Friday
- ✅ Suspicious Link: `bancolombia-credito.com` (not `bancolombia.com`)
- ✅ Action: BLOCK_AND_SHOW_OFFICIAL
- ✅ Risk Level: DANGEROUS

---

## Test Case 7: Fake Rappi Christmas Delivery
**Message:**
```
🎄 Rappi: Tu pedido de cena navideña está en camino.
Rastreo en tiempo real: http://rappi-track.xyz/order/98234
Propina sugerida: $20.000 COP - Paga aquí
```

**Expected Detection:**
- ✅ Entity: Rappi (detected)
- ✅ Intent: FINANCIAL_ACTION ("paga")
- ✅ Holiday Pattern: Christmas ("navideña", "🎄")
- ✅ Suspicious Link: `rappi-track.xyz` (not `rappi.com.co`)
- ✅ Action: BLOCK_AND_SHOW_OFFICIAL
- ✅ Risk Level: DANGEROUS

---

## Test Case 8: DaviPlata Year-End Bonus Scam
**Message:**
```
DaviPlata: 🎉 Bono de fin de año $150.000 COP disponible!
Reclama YA: http://daviplata-bono.com/claim2025
Válido solo HOY - 31 de Diciembre
```

**Expected Detection:**
- ✅ Entity: DaviPlata (detected)
- ✅ Intent: PRIZE_CLAIM ("bono", "reclama")
- ✅ Intent: URGENCY_PRESSURE ("ya", "solo hoy")
- ✅ Holiday Pattern: Year-end ("fin de año")
- ✅ Suspicious Link: `daviplata-bono.com` (not `daviplata.com`)
- ✅ Action: BLOCK_AND_SHOW_OFFICIAL
- ✅ Risk Level: DANGEROUS

---

## Test Case 9: Fake Éxito Hot Sale
**Message:**
```
Almacenes ÉXITO: HOT SALE 70% descuento!
Compra ahora: http://exito-hotsale.co/shop
Solo las primeras 100 personas. CORRE!
```

**Expected Detection:**
- ✅ Entity: Éxito (detected)
- ✅ Intent: URGENCY_PRESSURE ("solo", "primeras 100", "corre")
- ✅ Holiday Pattern: Hot Sale
- ✅ Suspicious Link: `exito-hotsale.co` (not `exito.com`)
- ✅ Action: BLOCK_AND_SHOW_OFFICIAL
- ✅ Risk Level: DANGEROUS

---

## Test Case 10: Legitimate Bancolombia (Should Pass)
**Message:**
```
Bancolombia: Compra aprobada por $89.500 COP en EXITO
Tarjeta *1234. Ver en app: https://www.bancolombia.com/personas
```

**Expected Detection:**
- ✅ Entity: Bancolombia, Éxito (both detected)
- ✅ Intent: NOTIFICATION_ONLY
- ✅ Official Link: `bancolombia.com` (whitelisted)
- ✅ Action: ALLOW_SAFE
- ✅ Risk Level: SAFE

---

## Summary Statistics Target
- **10 Test Cases Total**
- **8 Should Block** (80% dangerous - realistic December scenario)
- **2 Should Allow** (20% legitimate)
- **Holiday Keywords Covered:** Black Friday, Cyber Monday, Christmas, Hot Sale, Year-End
- **Entities Covered:** DHL, MercadoLibre, Nequi, Amazon, Bancolombia, Rappi, DaviPlata, Éxito
- **Attack Vectors:** Fake tracking, payment scams, prize scams, gift cards, fake promos
