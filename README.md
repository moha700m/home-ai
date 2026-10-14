# pc-local

وكيل محلي (BDK) يفحص قدرات جهازك ويقترح لك إعداد ونماذج تناسب الرام والمعالج وكرت الشاشة.

## تثبيت بنقرة واحدة (من GitHub)

**Mac / Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/moha700m/home-ai/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/moha700m/home-ai/main/install.ps1 | iex
```

بعدها:

```bash
cd ~/home-ai
npm run dev
```

افتح: [http://127.0.0.1:3847/playground](http://127.0.0.1:3847/playground)

## المتطلبات

- Node.js 22.13+
- Git
- حساب Cursor (للمحادثة بالذكاء الاصطناعي): `npx @cursor/bdk login` أو `CURSOR_API_KEY`

## التشغيل المحلي (يدوي)

```bash
npm install
npx @cursor/bdk serve --dir . --mode single --dev --port 3847
```

افتح: [http://127.0.0.1:3847/playground](http://127.0.0.1:3847/playground)

جرّب مثلاً: «وش قدرة جهازي؟»

## أوامر مفيدة

```bash
npx @cursor/bdk validate --dir .
npx @cursor/bdk info --dir . --json
npx @cursor/bdk call pc_specs --dir . --input '{}'
npx @cursor/bdk run --dir . --message "وش قدرة جهازي؟"
npm run check
```

## ماذا يفعل؟

- أداة `pc_specs`: تقرأ المعالج والرام ونظام التشغيل ولمحة عن الـ GPU، وتعطي مستوى قدرة (light / medium / strong) مع نماذج مقترحة.
- أداة `save_preference`: تحفظ تفضيلاً قصيراً (لغة، موديل مفضّل، هدف).
- الواجهة: Playground محلي على المنفذ `3847`.
