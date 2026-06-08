import sys
import json
import numpy as np
import tensorflow as tf
import joblib
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# ==============================
# Load model
# ==============================
with open(os.path.join(BASE_DIR, "config.json"), "r") as f:
    model = tf.keras.models.model_from_json(f.read())

model.load_weights(os.path.join(BASE_DIR, "model.weights.h5"))
scaler = joblib.load(os.path.join(BASE_DIR, "scaler.pkl"))

# ==============================
# Read input
# ==============================
input_arg = sys.argv[1]

if input_arg.endswith(".json"):
    with open(input_arg, "r") as f:
        data = json.load(f)
else:
    data = json.loads(input_arg)

# ==============================
# Prepare features (must match training)
# ==============================
features = [
    data["AS7263_610nm"],
    data["AS7263_680nm"],
    data["AS7263_730nm"],
    data["AS7263_760nm"],
    data["AS7263_810nm"],
    data["AS7263_860nm"],
    data["BME688_Aroma_Index_0_500"],
    data["Firmness_Average_Kg"],
    data.get("Days_After_Harvest", 0),
    data["Titratable_Acidity_mg_100g"],
    data["Brix_Average"]
]

input_array = np.array(features, dtype=np.float32).reshape(1, -1)
input_scaled = scaler.transform(input_array)
input_scaled = input_scaled.reshape(1, 11, 1)

# ==============================
# Prediction
# ==============================
prob = float(model.predict(input_scaled, verbose=0).ravel()[0])
confidence = max(prob, 1 - prob)

# Binary classification
if prob < 0.5:
    status = "Raw"
else:
    status = "Ripe"

# ==============================
# Sugar Conversion
# ==============================
brix = float(data["Brix_Average"])
sugar_mg_ml = brix * 10  # 1°Bx ≈ 10 mg/mL

# ==============================
# Time-to-consume logic
# ==============================
def time_to_consume_text(status: str, brix_avg: float, ripeness_conf: float) -> str:

    s = status.lower()
    b = float(brix_avg)
    c = float(ripeness_conf)

    # Confidence adjustment
    if c >= 0.85:
        conf_adj = 0
    elif c >= 0.65:
        conf_adj = 1
    else:
        conf_adj = 2

    # RAW logic
    if "raw" in s:
        if b <= 8:
            days_min, days_max = 4, 6
        elif b <= 10:
            days_min, days_max = 2, 4
        else:
            days_min, days_max = 1, 3

        days_min += conf_adj
        days_max += conf_adj
        days_max = min(days_max, 10)

        return f"{days_min}–{days_max} days"

    # RIPE logic
    if "ripe" in s:
        if b < 10:
            days_min, days_max = 1, 2
        elif b <= 14:
            days_min, days_max = 1, 2
        elif b <= 16:
            days_min, days_max = 0, 1
        else:
            return "Immediate"

        days_min = max(0, days_min + (conf_adj - 1))
        days_max = min(3, days_max + (conf_adj - 1))

        if days_max == 0:
            return "Immediate"
        if days_min == 0 and days_max == 1:
            return "Within 24 hours"
        if days_min == 1 and days_max == 1:
            return "1 day"

        return f"{days_min}–{days_max} days"

    # Fallback
    return "1–2 days"

# ==============================
# Final JSON Output
# ==============================
result = {
    "ripeness_status": status,
    "ripeness_confidence": round(confidence, 4),
    "sugar_mg_per_ml": f"{round(sugar_mg_ml, 2)} mg/mL",
    "time_to_consume_text": f"within {time_to_consume_text(status, brix, confidence)}"
}

print(json.dumps(result))