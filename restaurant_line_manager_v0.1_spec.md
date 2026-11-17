mak# 🍽️ Restaurant Line Manager – v0.1 Specification

## 1. Overview
This is the **first skeleton version (v0.1)** of the Restaurant Line Manager app.  
The purpose is to **simulate a realistic restaurant environment** using mock data, allowing us to test the ETA calculation when a user requests a table (e.g., “table for 5 — how long?”).  

We do **not yet have access to the ZoneSoft API**, so all data will be **mocked locally** (simulated historical and live data).

---

## 2. Core Goal
Allow a user to:
1. Visit a simple web page (QR code / link).
2. Choose a **party size**.
3. See an **estimated waiting time** for a table, based on the mock live restaurant data and the historical patterns.

No notifications, reservations, or user accounts are required yet — the focus is **simulating and testing the ETA logic**.

---

## 3. Data Model

### 3.1. Historical Data (`tables_history.csv`)
Simulate the restaurant’s last 30 days of data.  
Each row represents one completed table service.

| Column | Type | Description |
|--------|------|-------------|
| date | date | Date of service |
| table_id | integer | Table number or ID |
| party_size | integer | Number of people seated |
| start_time | datetime | When the table was opened |
| finish_time | datetime | When the table was closed |
| bill_printed_time | datetime | Optional, usually 5–10 minutes before finish |
| num_dishes | integer | Total dishes ordered |
| num_mains | integer | Number of main dishes |
| num_desserts | integer | Number of desserts |
| coffee | boolean | Whether coffees were ordered |
| alcoholic_drinks | boolean | Whether any alcoholic drinks were ordered |
| num_alcoholic_drinks | integer | Number of alcoholic drinks |
| last_order_time | datetime | Time of the last order |
| duration | integer | `finish_time - start_time` in minutes |

---

### 3.2. Live Data (`tables_live.csv`)
Represents the restaurant state at this exact moment.

| Column | Type | Description |
|--------|------|-------------|
| table_id | integer | Table number |
| table_size | integer | Seats at the table |
| status | string | One of: `free`, `occupied`, `bill_printed`, `cleaning` |
| start_time | datetime | If occupied, when it was opened |
| num_people | integer | Current number of people |
| elapsed_time | integer | Minutes since start |
| est_finish_time | datetime | Estimated finish time (optional precomputed) |

---

### 3.3. Table Configuration (`tables_config.json`)
Defines how many tables exist and which can be combined.

```json
[
  { "size": 2, "count": 20, "combinable": true },
  { "size": 4, "count": 10, "combinable": true },
  { "size": 6, "count": 3, "combinable": false },
  { "size": 10, "count": 1, "combinable": false }
]
```

The restaurant has **70 total seats**, is open **11:00–23:00**, closed on **Mondays**, and has **peak hours**:
- Lunch: 11:30–15:30  
- Dinner: 19:00–23:00  

---

## 4. Mock Data Generation
Generate fake data for **30 days × 2 sessions per day (lunch & dinner)**, randomizing:
- Party sizes (1–10)
- Durations (depending on size, e.g., 45–120 min)
- Dishes and drinks counts
- Bill printed time (finish – random 5–10 min)
- Weekday/weekend variations

For live data, simulate a **semi-full restaurant** (60–90% occupancy) at dinner rush hour.

---

## 5. Core Logic
When a user requests a table:
1. App receives `party_size`.
2. System looks at current `tables_live` state.
3. Estimates wait time:
   - Find the nearest available table or table combo.
   - Calculate average **remaining time** of ongoing tables that can accommodate that party size.
   - Use historical data to adjust based on averages by party size and time of day.
4. Return an **ETA window** (e.g., “Your wait is approximately 22–35 minutes”).

No need for AI models yet — just simple averages or heuristics for this version.

---

## 6. Tech Stack (for v0.1)
- **Backend:** Ruby on Rails (API mode)
- **Frontend:** Simple HTML/Tailwind page (form + display result)
- **Database:** Postgres (or CSV mock data read into memory)
- **Deployment:** Kamal (to DigitalOcean or local Docker)
- **Later integration:** ZoneSoft POS API

---

## 7. Endpoints
| Method | Route | Description |
|--------|--------|-------------|
| `GET /` | Main landing page (party size input) |
| `POST /estimate` | Input: `party_size`. Output: `{ eta_min, eta_max }` |
| `GET /live` | Debug route showing current simulated tables |
| `POST /reset_live` | Resets or regenerates live mock data |

---

## 8. Next Steps (after v0.1)
- Replace mock data with real POS data from ZoneSoft.
- Introduce live updates and notifications.
- Integrate machine learning model for smarter ETA estimation.
