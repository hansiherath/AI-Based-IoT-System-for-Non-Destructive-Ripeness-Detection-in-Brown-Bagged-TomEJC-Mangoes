import json
import sys
import numpy as np
import pandas as pd
import joblib

from health_core import (
    estimate_gi, estimate_gl_100g, grams_for_limit, blood_sugar_ranges, safety_override
)

STATUS_MODEL_PATH = "health_model/health_status_model.joblib"
GRAMS_MODEL_PATH = "health_model/limit_grams_model.joblib"

FEATURE_COLS = [
    "Brix_Average",
    "Time_to_Consume_days",
    "Weight_g",
    "Ripeness_Confidence",
    "Has_Diabetes",
    "Maturity_Class",
]


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "missing input json path"}))
        return

    input_path = sys.argv[1]
    with open(input_path, "r", encoding="utf-8") as f:
        payload = json.load(f)

    # Inputs required (from Model 1 + user)
    maturity = str(payload["Maturity_Class"]).strip().title()
    brix = float(payload["Brix_Average"])
    ttc = float(payload["Time_to_Consume_days"])
    conf = float(payload.get("Ripeness_Confidence", 0.85))
    weight = float(payload["Weight_g"])
    diabetic = int(bool(payload["Has_Diabetes"]))

    # Compute GI/GL
    gi = estimate_gi(maturity, ttc, conf)
    gl100 = estimate_gl_100g(brix, gi)
    gl150 = round(gl100 * 1.5, 2)

    # Load models
    status_model = joblib.load(STATUS_MODEL_PATH)
    grams_model = joblib.load(GRAMS_MODEL_PATH)

    # Build sample for RF
    sample = pd.DataFrame([{
        "Brix_Average": brix,
        "Time_to_Consume_days": ttc,
        "Weight_g": weight,
        "Ripeness_Confidence": conf,
        "Has_Diabetes": diabetic,
        "Maturity_Class": maturity
    }], columns=FEATURE_COLS)

    # Predict status
    status_pred = status_model.predict(sample)[0]

    # Safety override guarantees "Not Safe" works (GI/GL extreme)
    status = safety_override(status_pred, gi, gl100, diabetic)

    # Predict grams only for LIMIT
    grams = None
    if status == "Limit To Eat":
        grams = float(grams_model.predict(sample)[0])
        grams = min(grams, weight)
        grams = float(np.clip(grams, 50, 150))
        grams = float(round(grams, 1))

    # Build response for Flutter UI
    result = {
        "Health_Status": status,
        "Limit_Grams": grams,
        "GI_est": round(gi, 2),
        "GL_100g_est": round(gl100, 2),
        "GL_150g_est": gl150,
        #"BloodSugarRange": blood_sugar_ranges(status),
        "Message": (
            "Safe to eat based on estimated GI/GL."
            if status == "Safe To Eat"
            else (f"Limit intake. Suggested portion: {grams} g."
                  if status == "Limit To Eat"
                  else "Not recommended to eat based on estimated GI/GL.")
        )
    }

    print(json.dumps(result))


if __name__ == "__main__":
    main()