# 📊 Advanced Funnel Analysis for Mobile App Events

> A complete product analytics walkthrough using SQL & Python, simulating real-world funnel metrics: installs, retention, and conversion.

---

## 🚀 Getting Started

1. **Clone the repo**  
   ```bash
   git clone https://github.com/elvis07jr/mobileapp_funnel_analysis.git
   cd mobileapp_funnel_analysis
   ```

2. **Install dependencies**  
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the notebook**  
   ```bash
   jupyter notebook notebooks/funnel_analysis.ipynb
   ```

4. **Ensure dataset is present**  
   The notebook expects a file named `events.csv` inside the `data/` directory.

---

## 🧠 Project Overview

This project simulates funnel analysis using raw mobile app event logs. It's structured around key performance metrics that guide growth, retention, and monetization strategies.

### 📈 Key Metrics:
- **Install Count** → `event_name = 'app_install'`
- **Activation Count** → `event_name = 'app_open'`
- **Conversion Count** → `event_name = 'purchase'`
- **Retention** → DAU by day + user churn

---

## 🧮 Technologies & Tools

- **Python**: Pandas, DuckDB, Matplotlib, Seaborn
- **SQL**: Funnel queries via `duckdb.query()`
- **Data**: Synthetic mobile app event logs

---

## 🗃️ Data Schema

| Column       | Description               |
|--------------|---------------------------|
| user_id      | Unique user identifier    |
| event_name   | Event type (install, open, purchase) |
| event_time   | Timestamp of event        |

---

## 🔍 Sample Funnel Query

```sql
SELECT
  COUNT(DISTINCT CASE WHEN event_name = 'app_install' THEN user_id END) AS install_count,
  COUNT(DISTINCT CASE WHEN event_name = 'app_open' THEN user_id END) AS activation_count,
  COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_id END) AS conversion_count
FROM events;
```

---

## 📊 Visual Insights

Visualizations generated in the notebook include:
- ✅ Funnel chart: Install → Activation → Conversion
- 🔁 Retention curve: Daily Active Users
- 📉 Churn estimation: Drop-off trends

> These help product managers and growth teams understand behavior across the user journey.

---

## 🤖 Product Hypotheses

1. **Install drop-off is high:** Most users don’t activate within 24h.
2. **Retention is leaky:** DAU sharply declines after day 3.
3. **Conversion rates improve after 2nd app open.**

Each hypothesis is tested and interpreted using SQL + Python.

---

## 📘 Notebook

👉 [notebooks/funnel_analysis.ipynb](notebooks/funnel_analysis.ipynb)

---

## ⚠️ Disclaimer

This is a simulated dataset. All results are for educational purposes only.

---

## 🙌 Author

Built by [Elvis Tile](https://github.com/elvis07jr)

Feel free to ⭐ the repo or contribute improvements!
