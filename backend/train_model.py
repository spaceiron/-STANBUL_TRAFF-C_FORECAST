#!/usr/bin/env python3
"""
Train Random Forest density model (synthetic sample data for demo/retrain pipeline).
Usage:
  cd backend && python3 train_model.py
Writes: density_model_rf.pkl, scaler_rf.pkl, model_meta.json
"""
import json
import os
import random
from datetime import datetime, timedelta

import joblib
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ROUTES = [
    (41.0082, 28.9784),
    (41.1052, 29.0184),
    (41.0622, 28.9874),
    (41.0212, 29.0034),
]


def build_row(lat, lng, speed, at_time):
    hour = at_time.hour
    weekday = at_time.weekday()
    day = at_time.day
    speed_norm = min(speed / 180.0, 1.0)
    rush = 1.0 if 7 <= hour <= 9 or 17 <= hour <= 20 else 0.0
    base = 0.25 + 0.45 * rush + 0.1 * speed_norm
    noise = random.uniform(-0.08, 0.08)
    y = float(np.clip(base + noise, 0.05, 0.98))
    x = [
        hour, weekday, day,
        int(weekday >= 5),
        int(7 <= hour <= 9),
        int(17 <= hour <= 20),
        int(11 <= hour <= 14),
        int(hour >= 23 or hour <= 5),
        np.sin(2 * np.pi * hour / 24),
        np.cos(2 * np.pi * hour / 24),
        np.sin(2 * np.pi * weekday / 7),
        np.cos(2 * np.pi * weekday / 7),
        lat, lng, speed_norm,
    ]
    return x, y


def generate_dataset(n_samples=8000):
    rows_x, rows_y = [], []
    start = datetime.utcnow() - timedelta(days=30)
    for _ in range(n_samples):
        lat, lng = random.choice(ROUTES)
        speed = random.uniform(15, 90)
        t = start + timedelta(minutes=random.randint(0, 30 * 24 * 60))
        x, y = build_row(lat, lng, speed, t)
        rows_x.append(x)
        rows_y.append(y)
    return np.array(rows_x), np.array(rows_y)


def main():
    print('Generating synthetic training data...')
    X, y = generate_dataset(12000)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    scaler = StandardScaler()
    X_train_s = scaler.fit_transform(X_train)
    X_test_s = scaler.transform(X_test)

    model = RandomForestRegressor(n_estimators=120, max_depth=12, random_state=42, n_jobs=-1)
    model.fit(X_train_s, y_train)

    pred = model.predict(X_test_s)
    mae = mean_absolute_error(y_test, pred)
    rmse = mean_squared_error(y_test, pred) ** 0.5
    r2 = r2_score(y_test, pred)

    joblib.dump(model, os.path.join(BASE_DIR, 'density_model_rf.pkl'))
    joblib.dump(scaler, os.path.join(BASE_DIR, 'scaler_rf.pkl'))

    meta = {
        'features': [
            'hour', 'weekday', 'day', 'is_weekend', 'is_morning_rush', 'is_evening_rush',
            'is_midday', 'is_night', 'hour_sin', 'hour_cos', 'weekday_sin', 'weekday_cos',
            'LATITUDE', 'LONGITUDE', 'speed_norm',
        ],
        'max_vehicles': 548.0,
        'mae': round(mae, 4),
        'rmse': round(rmse, 4),
        'r2': round(r2, 4),
        'train_size': int(len(X_train)),
        'trainedAt': datetime.utcnow().isoformat(),
    }
    with open(os.path.join(BASE_DIR, 'model_meta.json'), 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2)

    print(f'Trained. MAE={mae:.4f} RMSE={rmse:.4f} R2={r2:.4f}')
    print('Saved model + scaler + model_meta.json')


if __name__ == '__main__':
    main()
