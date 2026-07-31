# tomodachi-infra

Konfigurasi infrastruktur (point B) untuk project microservice:
- **Kubernetes** — deployment/service dua service (`Auth Service (FastAPI)` & `Relationship Service (Golang)`)
- **Kong** — API Gateway, routing berdasarkan path prefix ke masing-masing service
- **ArgoCD** — GitOps, sinkronisasi otomatis dari repo ini ke cluster

## Struktur direktori

```
tomodachi-infra/
├── kubernetes/
│   ├── namespace.yaml              # namespace "tomodachi-app"
│   ├── auth-service/                    # Deployment, Service, ConfigMap (port 8000)
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── customization.yaml
│   ├── relationship-service/                     # Deployment, Service, ConfigMap (port 8080)
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── customization.yaml
│   └── kong/
│       ├── namespace.yaml          # namespace "kong"
│       ├── values.yaml             # Helm values untuk Kong Ingress Controller
│       ├── ingress-auth-service.yaml    # routing prefix /api/v1/{auth,profiles,interests,addresses,regions}
│       ├── ingress-relationship-service.yaml     # routing prefix /api/v1/relationships/friends/request
│       ├── plugins.yaml            # contoh KongPlugin (rate-limit, cors)
│       └── customization.yaml
└── argocd/
    ├── root-app.yaml               # app-of-apps, apply sekali di awal
    └── apps/
        ├── auth-app.yaml
        ├── relationship-app.yaml
        ├── kong-controller-app.yaml # install Kong via Helm chart resmi
        └── kong-routes-app.yaml     # apply Ingress + Plugin routing
```

## Peta routing

| Prefix | Service tujuan | Port |
|---|---|---|
| `/api/v1/auth` | auth-service | 8000 |
| `/api/v1/profiles` | auth-service | 8000 |
| `/api/v1/interests` | auth-service | 8000 |
| `/api/v1/addresses` | auth-service | 8000 |
| `/api/v1/regions` | auth-service | 8000 |
| `/api/v1/relationships/friends/request` | relationship-service | 8080 |

Semua Ingress memakai `konghq.com/strip-path: "false"`, sehingga path asli tetap
diteruskan apa adanya ke backend (tidak dipotong Kong). Sesuaikan ke `"true"` bila
service backend justru mengharapkan path tanpa prefix.

## Cara deploy

Sebelum mulai, pastikan:
1. Cluster Kubernetes sudah tersedia (`kubectl config current-context` mengarah ke cluster yang benar).
2. ArgoCD sudah terpasang di namespace `argocd`.
3. Ganti semua placeholder `<ORG>` (URL repo Git) dan `<REGISTRY>` (image container) sesuai punya Anda,
   lalu push isi direktori ini ke repo Git yang direferensikan oleh manifest ArgoCD.

Langkah:

```bash
# 1. Buat namespace dasar (opsional, ArgoCD juga bisa CreateNamespace otomatis)
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/kong/namespace.yaml

# 2. Apply root Application (app-of-apps) — ini satu-satunya perintah manual yang dibutuhkan
kubectl apply -f argocd/root-app.yaml

# 3. Pantau sinkronisasi
argocd app list
argocd app get tomodachi-infra-root
```

Setelah root app tersinkron, ArgoCD otomatis akan men-deploy:
- `auth-service` (Deployment + Service + ConfigMap)
- `relationship-service` (Deployment + Service + ConfigMap)
- `kong-controller` (Kong Ingress Controller via Helm)
- `kong-routes` (Ingress + Plugin routing)

## Menambahkan endpoint/prefix baru

- Prefix baru untuk AUTH (FastAPI) → tambahkan entri `paths` baru di `kubernetes/kong/ingress-auth-service.yaml`.
- Service baru (mis. service ketiga) → duplikasi folder `kubernetes/auth-service` atau `kubernetes/relationship-service`
  sebagai referensi, buat Ingress baru di `kubernetes/kong/`, lalu daftarkan sebagai
  ArgoCD Application baru di `argocd/apps/`.

## Catatan

- `values.yaml` Kong menggunakan mode **DB-less** (`env.database: "off"`), cocok untuk
  konfigurasi deklaratif via Kubernetes CRD/Ingress — tidak perlu Postgres terpisah.
- Readiness/liveness probe pada `deployment.yaml` mengarah ke path `.../health` sebagai
  contoh — sesuaikan dengan endpoint health-check aktual di masing-masing service.
- Resource `requests`/`limits` masih nilai default kecil, silakan disesuaikan dengan
  kebutuhan beban produksi sebenarnya.
