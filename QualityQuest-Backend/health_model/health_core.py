import numpy as np

# -------------------------
# CONFIG
# -------------------------
GRAMS_MIN = 50
GRAMS_MAX = 150

# Non-diabetic thresholds
GL_SAFE_MAX = 10.0
GL_LIMIT_MAX = 20.0  # >=20 -> Not Safe

# Diabetic stricter thresholds
GL_SAFE_MAX_DIAB = 8.0
GL_LIMIT_MAX_DIAB = 16.0

# Optional GI thresholds (you asked to consider GI & GL)
GI_SAFE_MAX = 55.0
GI_NOTSAFE_MIN = 70.0

TARGET_GL_FOR_LIMIT = 10.0


def clamp(x, a, b):
    return float(np.clip(float(x), float(a), float(b)))


# -------------------------
# GI & GL estimation
# -------------------------
def estimate_gi(maturity_class: str, time_to_consume_days: float, ripeness_conf: float) -> float:
    """
    GI proxy based on maturity + urgency + confidence
    """
    m = str(maturity_class).strip().lower()
    t = float(time_to_consume_days)
    c = clamp(ripeness_conf, 0.0, 1.0)

    # base GI
    if "raw" in m or "unripe" in m:
        base = 45.0
    elif "over" in m:
        base = 72.0
    else:
        base = 58.0

    # urgency effect
    if t <= 0:
        time_adj = 8.0
    elif t <= 1:
        time_adj = 5.0
    elif t <= 2:
        time_adj = 2.0
    elif t >= 4:
        time_adj = -3.0
    else:
        time_adj = 0.0

    # confidence scaling (low conf -> soften effect)
    scale = 0.5 + 0.5 * c  # 0.5..1.0
    gi = base + time_adj * scale

    return clamp(gi, 35.0, 80.0)


def estimate_gl_100g(brix_avg: float, gi: float) -> float:
    """
    GL proxy from Brix and GI.
    carbs/100g ≈ brix*1.2 (same style as your previous model)
    """
    b = float(brix_avg)
    carbs_100g = b * 1.2
    gl_100g = (float(gi) * carbs_100g) / 100.0
    return clamp(gl_100g, 0.0, 80.0)


# -------------------------
# Label logic (ground-truth proxy)
# -------------------------
def label_health_status(gi: float, gl_100g: float, has_diabetes: int) -> str:
    """
    Uses BOTH GI and GL to label:
      Safe: GI<=55 and GL<safe_threshold
      Not Safe: GI>=70 or GL>=limit_threshold
      Limit: otherwise
    """
    diabetic = int(has_diabetes) == 1
    safe_gl = GL_SAFE_MAX_DIAB if diabetic else GL_SAFE_MAX
    limit_gl = GL_LIMIT_MAX_DIAB if diabetic else GL_LIMIT_MAX

    if gi <= GI_SAFE_MAX and gl_100g < safe_gl:
        return "Safe To Eat"
    if gi >= GI_NOTSAFE_MIN or gl_100g >= limit_gl:
        return "Not Safe To Eat"
    return "Limit To Eat"


# -------------------------
# Portion size for LIMIT only
# -------------------------
def grams_for_limit(gl_100g: float, weight_g: float) -> float:
    """
    grams ≈ (TARGET_GL_FOR_LIMIT / gl_100g) * 100
    then clamp to [50,150] and <= weight_g
    """
    gl = float(gl_100g)
    w = float(weight_g)

    if gl <= 0:
        grams = GRAMS_MAX
    else:
        grams = (TARGET_GL_FOR_LIMIT / gl) * 100.0

    grams = min(grams, w)
    grams = clamp(grams, GRAMS_MIN, GRAMS_MAX)
    return float(round(grams, 1))


# -------------------------
# UI helper
# -------------------------
def blood_sugar_ranges(status: str) -> dict:
    s = str(status).strip().lower()
    if "safe" in s and "not" not in s:
        return {"fasting": "70–99 mg/dL", "post_meal": "< 140 mg/dL"}
    if "limit" in s:
        return {"fasting": "100–125 mg/dL", "post_meal": "140–199 mg/dL"}
    return {"fasting": "≥ 126 mg/dL", "post_meal": "≥ 200 mg/dL"}


# -------------------------
# Inference safety override (guarantee Not Safe works)
# -------------------------
def safety_override(status_pred: str, gi: float, gl_100g: float, has_diabetes: int) -> str:
    """
    Even if RF predicts something else, override to Not Safe when GI/GL is clearly dangerous.
    This prevents missing 'Not Safe' in deployment.
    """
    diabetic = int(has_diabetes) == 1
    limit_gl = GL_LIMIT_MAX_DIAB if diabetic else GL_LIMIT_MAX

    if gi >= GI_NOTSAFE_MIN or gl_100g >= limit_gl:
        return "Not Safe To Eat"
    return status_pred