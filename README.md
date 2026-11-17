# Restaurant Line Manager - v0.1

Personal Rails prototype for anonymous restaurant wait-time estimation. This version assigns automatic party labels and does not ask for customer names or contact details. All demo table and historical data are generated locally; no real restaurant or guest data is included.

Repository history starts with this first public upload of the existing prototype. No earlier Git commits were available to publish.


A smart waitlist management system that provides estimated wait times for restaurant customers based on live table status and historical data patterns.

## Overview

This is the first skeleton version (v0.1) of the Restaurant Line Manager. It simulates a realistic restaurant environment using mock data to test ETA (Estimated Time of Arrival) calculation when customers request tables.

**Key Features:**
- Real-time wait time estimation based on party size
- Live table status monitoring (debug view)
- Historical data analysis for accurate predictions
- Simple, mobile-friendly web interface
- JSON API for integration

---

## Tech Stack

- **Ruby:** 3.x
- **Rails:** 8.0.2.1
- **Frontend:** HTML + Tailwind CSS
- **Data:** CSV files (no database required for v0.1)

---

## Quick Start

### Prerequisites

- Ruby 3.x installed
- Rails 8.x installed
- Bundler gem

### Installation

1. **Clone or navigate to the project directory:**
   ```bash
   cd "Restaurant line manager"
   ```

2. **Install dependencies:**
   ```bash
   bundle install
   ```

3. **Generate mock data:**
   ```bash
   # Generate 30 days of historical restaurant data
   rails data:generate_historical

   # Generate current live table status
   rails data:generate_live
   ```

4. **Start the server:**
   ```bash
   rails server -p 4000
   ```

5. **Visit the application:**
   ```
   http://localhost:4000
   ```

---

## Usage

### Web Interface

1. **Home Page** (`/`)
   - Select party size (1-12 people)
   - Click "Get Wait Time"
   - View estimated wait time

2. **Live Status Page** (`/live`)
   - View all table statuses
   - See restaurant statistics
   - Regenerate mock data for testing

### API Endpoints

#### Calculate Wait Time
```bash
POST /estimate.json
Parameters: party_size (integer, 1-12)

# Example:
curl -X POST http://localhost:4000/estimate.json \
  -d "party_size=4"

# Response:
{
  "success": true,
  "party_size": 4,
  "eta_min": 0,
  "eta_max": 5,
  "status": "available_now",
  "message": "Great news! We have tables available now."
}
```

#### Get Live Table Status
```bash
GET /live.json

# Example:
curl http://localhost:4000/live.json

# Response:
{
  "tables": [...],
  "stats": {
    "total_tables": 34,
    "free_tables": 13,
    "occupied_tables": 21,
    "occupancy_rate": 61.8
  }
}
```

#### Regenerate Mock Data
```bash
POST /live/reset

# Example:
curl -X POST http://localhost:4000/live/reset
```

---

## Project Structure

```
Restaurant line manager/
├── app/
│   ├── controllers/
│   │   ├── estimate_controller.rb    # ETA calculation endpoint
│   │   ├── live_controller.rb        # Live status & debug
│   │   └── home_controller.rb        # Landing page
│   ├── services/
│   │   ├── table_manager.rb          # Table data management
│   │   └── eta_calculator.rb         # Wait time calculation
│   └── views/
│       ├── home/index.html.erb       # Main landing page
│       ├── estimate/create.html.erb  # ETA results
│       └── live/index.html.erb       # Live table status
├── data/
│   ├── tables_config.json            # Restaurant configuration
│   ├── tables_history.csv            # 30 days of mock data (generated)
│   └── tables_live.csv               # Current table status (generated)
├── lib/tasks/
│   ├── generate_historical_data.rake # Generate historical data
│   └── generate_live_data.rake       # Generate live data
└── config/
    └── routes.rb                     # API routes
```

---

## Restaurant Configuration

The mock restaurant has the following setup:

- **Total Tables:** 34
- **Total Seats:** 70
- **Table Configuration:**
  - 20x 2-seat tables (combinable)
  - 10x 4-seat tables (combinable)
  - 3x 6-seat tables
  - 1x 10-seat table

- **Operating Hours:** 11:00 AM - 11:00 PM
- **Closed:** Mondays
- **Peak Hours:**
  - Lunch: 11:30 AM - 3:30 PM
  - Dinner: 7:00 PM - 11:00 PM

---

## How It Works

### ETA Calculation Algorithm

The system calculates wait times using a multi-factor approach:

1. **Check for immediate availability:**
   - Looks for free tables that fit the party size
   - If available, returns 0-5 minute wait (seating time)

2. **Check tables finishing soon:**
   - Analyzes occupied tables with estimated finish times
   - Finds suitable tables becoming available within 60 minutes
   - Adds 5-10 minutes for cleaning/turnover

3. **Calculate estimated wait:**
   - Uses historical data to estimate average meal duration by party size
   - Factors in current occupancy rate
   - Applies wait multiplier based on restaurant busyness

### Data Generation

**Historical Data** (`lib/tasks/generate_historical_data.rake`):
- Generates 30 days of completed table service records
- Simulates lunch and dinner sessions
- Randomizes party sizes, meal durations, orders
- Accounts for weekday/weekend variations
- Respects closed Mondays

**Live Data** (`lib/tasks/generate_live_data.rake`):
- Simulates current restaurant state at dinner rush (8:00 PM)
- Sets 60-90% occupancy
- Distributes tables across statuses:
  - **Free:** Available tables
  - **Occupied:** Currently dining
  - **Bill Printed:** Finishing soon
  - **Cleaning:** Being prepared

---

## Development

### Regenerate Mock Data

```bash
# Regenerate historical data (30 days)
rails data:generate_historical

# Regenerate live restaurant state
rails data:generate_live
```

### Run Tests

```bash
# Test ETA calculator manually
rails runner "
calc = EtaCalculator.new
result = calc.calculate(4)
puts result.inspect
"
```

### View Routes

```bash
rails routes
```

---

## Testing

### Manual Testing Checklist

- [ ] Home page loads correctly
- [ ] Party size form submission works
- [ ] ETA results display properly
- [ ] Live status page shows all tables
- [ ] Regenerate data button works
- [ ] JSON API returns valid responses
- [ ] Edge cases handled (party size 1, 10, >12)

### Edge Cases

The system handles various edge cases:

- **Party of 1:** Finds smallest available table
- **Party of 10:** Uses the 10-seat table
- **Party > 12:** Returns validation error
- **No tables available:** Estimates wait based on averages
- **All tables free:** Returns immediate availability

---

## Known Limitations (v0.1)

This is a prototype version with the following limitations:

1. **Mock Data Only:** Uses simulated data instead of real POS integration
2. **No User Accounts:** No authentication or user management
3. **No Reservations:** Walk-in wait time estimation only
4. **No Notifications:** No SMS/email alerts when tables are ready
5. **Single Restaurant:** Designed for one location
6. **No Deployment:** Local development only

---

## Roadmap (v0.2+)

### Integration
- [ ] Connect to ZoneSoft POS API
- [ ] Real-time table status updates
- [ ] Actual customer order data

### Features
- [ ] Customer notifications (SMS/email)
- [ ] Reservation system
- [ ] Machine learning for smarter predictions
- [ ] Multi-restaurant support
- [ ] Admin dashboard

### Deployment
- [ ] Kamal configuration
- [ ] DigitalOcean deployment
- [ ] SSL/HTTPS setup
- [ ] Production database

---

## Troubleshooting

### Port Already in Use

If port 4000 is already in use:
```bash
# Use a different port
rails server -p 4001

# Or kill the process using port 4000
lsof -ti:4000 | xargs kill -9
```

### Data Files Missing

If CSV files are missing:
```bash
# Regenerate all data
rails data:generate_historical
rails data:generate_live
```

### Tailwind CSS Not Loading

If styles aren't showing:
```bash
# Compile Tailwind CSS
rails tailwindcss:build

# Or run in dev mode
bin/dev
```

---

## Documentation

- **Development Plan:** See `DEVELOPMENT_PLAN.md` for detailed progress tracking
- **Original Spec:** See `restaurant_line_manager_v0.1_spec.md` for project requirements

---

## Contributing

This is a prototype project. For questions or suggestions, refer to the project specification and development plan documents.

---

## License

Internal project - Not for public distribution.

---

## Support

For issues or questions about this prototype:
1. Check `DEVELOPMENT_PLAN.md` for implementation details
2. Review `restaurant_line_manager_v0.1_spec.md` for requirements
3. Consult the code comments in service files

---

**Status:** ✅ v0.1 Complete - Ready for local testing and demonstration


## License

Original source code is licensed under the MIT License; see [LICENSE](LICENSE). Dependencies retain their own licenses.
