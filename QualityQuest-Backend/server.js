require("dotenv").config();
const express = require("express");
const cors = require("cors");
const mysql = require("mysql2");

const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const app = express();
app.use(cors());
app.use(express.json());

// ---------- DB CONNECTION ----------
const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,
});

db.connect((err) => {
  if (err) {
    console.error("❌ DB connection failed:", err.message);
    process.exit(1);
  }
  console.log("✅ Connected to AWS RDS MySQL");
});

// ---------- TEST ----------
app.get("/", (req, res) => {
  res.send("QualityQuest Backend Running 🚀");
});



// =====================================================
// ===================== REGISTER =======================
// =====================================================
app.post("/register", (req, res) => {
  const { email, password, fname, lname } = req.body;

  if (!email || !password || !fname) {
    return res.status(400).json({ message: "Please fill in all required fields correctly" });
  }

  db.beginTransaction((err) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Transaction error" });
    }

    // 1️⃣ USERS
    const userSql = `
      INSERT INTO USERS (Email, Password, UserType, AccountStatus)
      VALUES (?, ?, 'Customer', 'Active')
    `;

    db.query(userSql, [email, password], (err, userResult) => {
      if (err) {
        return db.rollback(() => {
          if (err.code === "ER_DUP_ENTRY") {
            return res.status(409).json({ message: "This email is already registered" });
          }
          return res.status(500).json({ message: err.sqlMessage });
        });
      }

      const userId = userResult.insertId;

      // 2️⃣ USER_NAME
      const nameSql = `
        INSERT INTO USER_NAME (UserID, Fname, Lname)
        VALUES (?, ?, ?)
      `;

      db.query(nameSql, [userId, fname, lname || ""], (err) => {
        if (err) {
          return db.rollback(() =>
            res.status(500).json({ message: err.sqlMessage })
          );
        }

        // 3️⃣ CUSTOMER
        const customerSql = `
          INSERT INTO CUSTOMER (UserID, IsDiabetic)
          VALUES (?, 0)
        `;

        db.query(customerSql, [userId], (err) => {
          if (err) {
            return db.rollback(() =>
              res.status(500).json({ message: err.sqlMessage })
            );
          }

          db.commit((err) => {
            if (err) {
              return db.rollback(() =>
                res.status(500).json({ message: "Commit failed" })
              );
            }

            res.json({
              message: "Account successfully created! Please log in to continue",
              userId,
            });
          });
        });
      });
    });
  });
});


// =====================================================
// ====================== LOGIN ==========================
// =====================================================
app.post("/login", (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: "Please fill missing fields" });
  }

  const sql = `
  SELECT 
    U.UserID,
    U.Email,
    U.Password,
    U.ProfilePicture,
    N.Fname,
    N.Lname,
    C.IsDiabetic
  FROM USERS U
  JOIN USER_NAME N ON U.UserID = N.UserID
  JOIN CUSTOMER C ON U.UserID = C.UserID
  WHERE LOWER(TRIM(U.Email)) = LOWER(TRIM(?))
    AND TRIM(U.Password) = TRIM(?)
  `;

  db.query(sql, [email, password], (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Server error" });
    }

    if (results.length === 0) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    res.json({
      message: "Login successful. Welcome!",
      user: results[0],
    });
  });
});


// =====================================================
// ============= UPDATE DIABETES STATUS =================
// =====================================================

app.put("/customer/diabetes", (req, res) => {
  const { userId, isDiabetic } = req.body;

  if (userId === undefined || isDiabetic === undefined) {
    return res.status(400).json({ message: "Missing data" });
  }

  const sql = `
    UPDATE CUSTOMER
    SET IsDiabetic = ?
    WHERE UserID = ?
  `;

  db.query(sql, [isDiabetic, userId], (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Database error" });
    }

    res.json({ message: "Diabetes status updated successfully" });
  });
});



// =====================================================
// ============ LATEST MANGO RESULT =====================
// =====================================================
app.get("/latest-mango-result/:userId", (req, res) => {
  const { userId } = req.params;

  const sql = `
    SELECT 
      R.RipenessStage,
      R.SugarLevel,
      R.TimeToConsume,
      R.HealthRecommendation
    FROM RESULT R
    WHERE R.UserID = ?
    ORDER BY R.ResultID DESC
    LIMIT 1
  `;

  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Server error" });
    }

    if (!results || results.length === 0) {
      return res.json({
        RipenessStage: "-",
        SugarLevel: "-",
        TimeToConsume: "-",
        healthRecommendation: "Unknown",
        sensorStatus: "NO_MANGO",
      });
    }

    const row = results[0];

    res.json({
      RipenessStage: row.RipenessStage,
      SugarLevel: row.SugarLevel,
      TimeToConsume: row.TimeToConsume,
      healthRecommendation: row.HealthRecommendation, // ⭐ REAL VALUE FROM DB
      sensorStatus: "MANGO_DETECTED",
    });
  });
});


// ---------- START ----------
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
});

// =====================================================
// ================== ADMIN AUTH MIDDLEWARE =============
// =====================================================
function verifyAdmin(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader)
    return res.status(403).json({ message: "No token provided" });

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (decoded.role !== "Admin")
      return res.status(401).json({ message: "Admin access only" });

    req.admin = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ message: "Invalid or expired token" });
  }
}

// =====================================================
// ===================== ADMIN LOGIN ====================
// =====================================================
app.post("/admin/login", (req, res) => {
  const { email, password } = req.body;

  if (!email || !password)
    return res.status(400).json({ message: "Missing fields" });

  const sql = `
    SELECT U.UserID, U.Password
    FROM USERS U
    JOIN ADMIN A ON U.UserID = A.UserID
    WHERE LOWER(U.Email) = LOWER(?)
      AND U.UserType = 'Admin'
      AND U.AccountStatus = 'Active'
  `;

  db.query(sql, [email], async (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Server error" });
    }

    if (results.length === 0)
      return res.status(401).json({ message: "Invalid admin credentials" });

    const admin = results[0];
    const match = await bcrypt.compare(password, admin.Password);

    if (!match)
      return res.status(401).json({ message: "Invalid admin credentials" });

    const token = jwt.sign(
      { userId: admin.UserID, role: "Admin" },
      process.env.JWT_SECRET,
      { expiresIn: "2h" }
    );

    res.json({
      message: "Admin login successful",
      token,
    });
  });
});

// =====================================================
// ⭐ NEW API — ADMIN GET CUSTOMERS (ADDED)
// =====================================================
app.get("/admin/customers", verifyAdmin, (req, res) => {
  const sql = `
    SELECT 
      U.UserID,
      CONCAT(N.Fname,' ',N.Lname) AS name,
      U.Email,
      U.AccountStatus,
      U.ProfilePicture
    FROM USERS U
    JOIN USER_NAME N ON U.UserID = N.UserID
    WHERE U.UserType = 'Customer'
    ORDER BY U.UserID DESC
  `;

  db.query(sql, (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Server error" });
    }

    res.json(results);
  });
});

// =====================================================
// ============== ADMIN – ML MODEL STATUS ===============
// =====================================================
app.get("/admin/model-status", verifyAdmin, (req, res) => {
  const sql = `
    SELECT Accuracy, LastTrained
    FROM ML_MODEL
    ORDER BY ModelID DESC
    LIMIT 1
  `;

  db.query(sql, (err, results) => {
    if (err)
      return res.status(500).json({ message: "Server error" });

    res.json(results[0]);
  });
});

// =====================================================
// ============== ADMIN – SENSOR MONITORING ==============
// =====================================================
app.get("/admin/sensors", verifyAdmin, (req, res) => {
  const sql = `
    SELECT SensorID, Status, LastMaintenance
    FROM SENSOR_SYSTEM
  `;

  db.query(sql, (err, results) => {
    if (err)
      return res.status(500).json({ message: "Server error" });

    res.json(results);
  });
});

// =====================================================
// ⭐ UPDATE PROFILE IMAGE
// =====================================================
app.put("/customer/profile-image", (req, res) => {
  const { userId, profilePicture } = req.body;

  const sql = `
    UPDATE USERS
    SET ProfilePicture = ?
    WHERE UserID = ?
  `;

  db.query(sql, [profilePicture, userId], (err) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Database error" });
    }

    res.json({ message: "Profile updated" });
  });
});

// =====================================================
// ⭐ classification Model To backend node.js api
// =====================================================

const { exec } = require("child_process");
const fs = require("fs");
const path = require("path");

app.post("/predict", (req, res) => {
  try {
    const inputPath = path.join(__dirname, "temp_input.json");

    // Save JSON body to file
    fs.writeFileSync(inputPath, JSON.stringify(req.body));

    exec(
      `venv\\Scripts\\python classification_model\\ml_predict.py temp_input.json`,
      (error, stdout, stderr) => {
        if (error) {
          console.error("EXEC ERROR:", error);
          console.error("STDERR:", stderr);
          return res.status(500).json({ error: "Prediction failed" });
        }

        const lines = stdout.trim().split("\n");
        const lastLine = lines[lines.length - 1];
        const result = JSON.parse(lastLine);
        res.json(result);
      }
    );
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
});

// =====================================================
// ⭐ Health Recommendation Model To backend node.js api
// =====================================================

app.post("/health_predict", (req, res) => {
  try {
    const inputPath = path.join(__dirname, "temp_health_input.json");

    fs.writeFileSync(inputPath, JSON.stringify(req.body));

    exec(
      `venv\\Scripts\\python health_model\\health_predict.py temp_health_input.json`,
      (error, stdout, stderr) => {
        if (error) {
          console.error("EXEC ERROR:", error);
          console.error("STDERR:", stderr);
          return res.status(500).json({ error: "Health prediction failed" });
        }

        const lastLine = stdout.trim().split("\n").pop();
        res.json(JSON.parse(lastLine));
      }
    );
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
});

