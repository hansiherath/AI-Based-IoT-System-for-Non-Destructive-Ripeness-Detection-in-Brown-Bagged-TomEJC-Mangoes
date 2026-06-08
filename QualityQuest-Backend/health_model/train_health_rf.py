import numpy as np
import pandas as pd
import joblib

from sklearn.model_selection import train_test_split, StratifiedKFold, cross_val_score
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.pipeline import Pipeline
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, f1_score
from sklearn.metrics import mean_absolute_error, mean_squared_error

from health_core import (
    estimate_gi, estimate_gl_100g, label_health_status, grams_for_limit
)

import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(BASE_DIR, "Dataset.csv")
RANDOM_STATE = 42


# -------------------------
# Load + clean
# -------------------------
df = pd.read_csv(DATA_PATH)
df["Maturity_Class"] = df["Maturity_Class"].astype(str).str.strip().str.title()

for col in ["Brix_Average", "Weight_g", "Days_After_Harvest"]:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

df = df.dropna(subset=["Brix_Average", "Weight_g", "Days_After_Harvest", "Maturity_Class"]).copy()
df = df.reset_index(drop=True)

np.random.seed(RANDOM_STATE)


# -------------------------
# Training proxy: Time_to_Consume_days
# -------------------------
def compute_time_to_consume(row):
    d = float(row["Days_After_Harvest"])
    m = str(row["Maturity_Class"]).strip().title()
    if m == "Raw":
        t = 7 - d
    else:
        t = 3 - d
    return float(np.clip(t, 0, 7))

df["Time_to_Consume_days"] = df.apply(compute_time_to_consume, axis=1)


# -------------------------
# Ensure confidence + diabetes columns exist (training proxies)
# -------------------------
if "Ripeness_Confidence" not in df.columns:
    def proxy_conf(maturity):
        m = str(maturity).lower()
        if "raw" in m:
            return np.random.uniform(0.75, 0.98)
        return np.random.uniform(0.65, 0.95)
    df["Ripeness_Confidence"] = df["Maturity_Class"].apply(proxy_conf)

if "Has_Diabetes" not in df.columns:
    df["Has_Diabetes"] = np.random.choice([0, 1], size=len(df), p=[0.7, 0.3])

df["Has_Diabetes"] = df["Has_Diabetes"].astype(int)
df["Ripeness_Confidence"] = df["Ripeness_Confidence"].astype(float)


# -------------------------
# Compute GI/GL and labels
# -------------------------
df["GI_est"] = df.apply(lambda r: estimate_gi(r["Maturity_Class"], r["Time_to_Consume_days"], r["Ripeness_Confidence"]), axis=1)
df["GL_100g_est"] = df.apply(lambda r: estimate_gl_100g(r["Brix_Average"], r["GI_est"]), axis=1)

df["Health_Status"] = df.apply(lambda r: label_health_status(r["GI_est"], r["GL_100g_est"], r["Has_Diabetes"]), axis=1)

df["Limit_Grams"] = np.nan
mask_limit = df["Health_Status"] == "Limit To Eat"
df.loc[mask_limit, "Limit_Grams"] = df.loc[mask_limit].apply(lambda r: grams_for_limit(r["GL_100g_est"], r["Weight_g"]), axis=1)

#print("\nInitial class distribution:\n", df["Health_Status"].value_counts())


# -------------------------
# Augment if Not Safe is missing
# -------------------------
if "Not Safe To Eat" not in df["Health_Status"].value_counts().index:
    #print("\n⚠️ 'Not Safe To Eat' missing. Augmenting synthetic high-risk samples...")

    base = df[df["Maturity_Class"].str.lower().str.contains("ripe")].copy()
    if len(base) == 0:
        base = df.copy()

    synth = base.sample(min(20, len(base)), random_state=RANDOM_STATE).copy()

    # Make them high risk:
    synth["Brix_Average"] = synth["Brix_Average"] + np.random.uniform(6, 12, size=len(synth))
    synth["Time_to_Consume_days"] = np.random.uniform(0, 1, size=len(synth))
    synth["Has_Diabetes"] = 1
    synth["Ripeness_Confidence"] = np.random.uniform(0.80, 0.98, size=len(synth))

    synth["GI_est"] = synth.apply(lambda r: estimate_gi(r["Maturity_Class"], r["Time_to_Consume_days"], r["Ripeness_Confidence"]), axis=1)
    synth["GL_100g_est"] = synth.apply(lambda r: estimate_gl_100g(r["Brix_Average"], r["GI_est"]), axis=1)
    synth["Health_Status"] = synth.apply(lambda r: label_health_status(r["GI_est"], r["GL_100g_est"], r["Has_Diabetes"]), axis=1)

    synth = synth[synth["Health_Status"] == "Not Safe To Eat"]
    df = pd.concat([df, synth], ignore_index=True)

    #print("Added Not Safe samples:", len(synth))
    #print("\nFinal class distribution:\n", df["Health_Status"].value_counts())


# -------------------------
# Features
# -------------------------
FEATURE_COLS = [
    "Brix_Average",
    "Time_to_Consume_days",
    "Weight_g",
    "Ripeness_Confidence",
    "Has_Diabetes",
    "Maturity_Class",
]
NUM_FEATURES = ["Brix_Average", "Time_to_Consume_days", "Weight_g", "Ripeness_Confidence", "Has_Diabetes"]
CAT_FEATURES = ["Maturity_Class"]

X = df[FEATURE_COLS].copy()
y = df["Health_Status"].copy()

all_maturity_classes = sorted(df["Maturity_Class"].unique().tolist())


preprocess = ColumnTransformer(
    transformers=[
        ("num", Pipeline([("scaler", StandardScaler())]), NUM_FEATURES),
        ("cat", Pipeline([("onehot", OneHotEncoder(handle_unknown="ignore", categories=[all_maturity_classes]))]), CAT_FEATURES),
    ],
    remainder="drop"
)


# -------------------------
# Model A: Status classifier
# -------------------------
status_model = Pipeline(steps=[
    ("preprocess", preprocess),
    ("classifier", RandomForestClassifier(
        n_estimators=500,
        max_depth=14,
        min_samples_split=6,
        min_samples_leaf=3,
        random_state=RANDOM_STATE,
        n_jobs=-1
    ))
])

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=RANDOM_STATE, stratify=y
)

status_model.fit(X_train, y_train)
pred = status_model.predict(X_test)

#print("\n✅ STATUS MODEL")
#print("Accuracy:", accuracy_score(y_test, pred))
#print("Macro F1:", f1_score(y_test, pred, average="macro"))
#print(confusion_matrix(y_test, pred))
#print(classification_report(y_test, pred))

skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=RANDOM_STATE)
cv_f1 = cross_val_score(status_model, X, y, cv=skf, scoring="f1_macro")
#print("✅ CV F1 mean±std:", cv_f1.mean(), "±", cv_f1.std())


# -------------------------
# Model B: Grams regressor (Limit only)
# -------------------------
df_limit = df[df["Health_Status"] == "Limit To Eat"].copy()
Xg = df_limit[FEATURE_COLS].copy()
yg = df_limit["Limit_Grams"].copy()

grams_model = Pipeline(steps=[
    ("preprocess", preprocess),
    ("regressor", RandomForestRegressor(
        n_estimators=500,
        max_depth=14,
        min_samples_split=6,
        min_samples_leaf=3,
        random_state=RANDOM_STATE,
        n_jobs=-1
    ))
])

Xg_train, Xg_test, yg_train, yg_test = train_test_split(
    Xg, yg, test_size=0.2, random_state=RANDOM_STATE
)

grams_model.fit(Xg_train, yg_train)
gpred = grams_model.predict(Xg_test)

#print("\n✅ GRAMS MODEL (LIMIT ONLY)")
#print("MAE:", mean_absolute_error(yg_test, gpred))
#print("RMSE:", np.sqrt(mean_squared_error(yg_test, gpred)))


# -------------------------
# Save
# -------------------------
joblib.dump(status_model, "health_model/health_status_model.joblib")
joblib.dump(grams_model, "health_model/limit_grams_model.joblib")
#print("\n✅ Saved: health_model/health_status_model.joblib, health_model/limit_grams_model.joblib")