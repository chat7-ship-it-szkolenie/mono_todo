# mono_todo

Monorepo dla projektu Todo Workshop składające się z trzech serwisów:

| Katalog | Repo źródłowe | Opis |
|---|---|---|
| `services/backend` | `todo_ai_worshop` | FastAPI + SQLite + AI priority |
| `services/frontend` | `todo_workshop_frontend` | React + Vite |
| `services/selenium` | `todo_selenium` | Testy E2E (Selenium) |

## Struktura

```
mono_todo/
├── services/
│   ├── backend/    # Python / FastAPI
│   ├── frontend/   # JavaScript / React
│   └── selenium/   # Python / Pytest + Selenium
└── README.md
```

## Aktualizacja subdrzew

```bash
# Backend
git subtree pull --prefix=services/backend todo_ai_worshop main --squash

# Frontend
git subtree pull --prefix=services/frontend todo_workshop_frontend main --squash

# Selenium
git subtree pull --prefix=services/selenium todo_selenium main --squash
```
