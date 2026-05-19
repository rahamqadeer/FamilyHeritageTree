# Family Digital Heritage Vault

A mobile-first system for securely storing, organizing, and passing down family memories across generations. Built with Flutter and Node.js, powered by Supabase.

## Tech Stack

| Component | Technology |
|-----------|------------|
| **Backend** | Node.js, Express, Supabase |
| **Mobile** | Flutter 3, Supabase Flutter |
| **Database** | PostgreSQL (Supabase) |
| **Auth** | Supabase Auth |
| **Storage** | Supabase Storage |

## Project Structure

```
├── backend/          # Node.js + Express REST API
│   ├── src/
│   │   ├── config/   # Supabase client, env config
│   │   ├── db/       # Database schema
│   │   ├── middlewares/
│   │   └── routes/
│   └── package.json
│
└── mobile/           # Flutter app
    ├── lib/
    │   ├── main.dart
    │   └── src/
    │       ├── core/config/    # Supabase config
    │       └── features/       # Auth, dashboard, memories, family tree
    └── pubspec.yaml
```

## Prerequisites

- **Node.js** 18+
- **Flutter** 3.x
- **Supabase** account with a project

## Installation

### 1. Clone the repository

```bash
git clone <repository-url>
cd FamilyHeritageTree
```

### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env
```

Edit `.env` with your Supabase credentials:

```env
PORT=4000
NODE_ENV=development
JWT_SECRET=your-secret-key

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_POSTGRES_CONNECTION_STRING=postgres://...  # Optional, for schema init
```

### 3. Mobile Setup

```bash
cd mobile

# Install dependencies
flutter pub get
```

Update Supabase credentials in `lib/src/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
}
```

## Running the App

### Backend

```bash
cd backend

# Development (with hot reload)
npm run dev

# Production
npm start
```

The API will be available at `http://localhost:4000`

### Mobile

```bash
cd mobile

# Run on Chrome (web)
flutter run -d chrome

# Run on connected device/emulator
flutter run

# Build for web
flutter build web
```

## Supabase Setup

### 1. Create Storage Bucket

In Supabase Dashboard:
1. Go to **Storage** → **New bucket**
2. Name: `memories`
3. Set to Private (requires authentication)

### 2. Initialize Database Schema

```bash
cd backend
npm run init:schema
```

Or run the SQL in `backend/src/db/initSchema.js` directly in Supabase SQL Editor.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/api/families` | Create family vault |
| GET | `/api/families` | List user's families |
| POST | `/api/families/:id/invite` | Invite family member |
| GET | `/api/family-tree/:familyId` | Get family tree |
| POST | `/api/family-tree/:familyId/nodes` | Add tree node |
| POST | `/api/memories` | Create memory |
| GET | `/api/memories?familyId=:id` | List memories |

## License

MIT
