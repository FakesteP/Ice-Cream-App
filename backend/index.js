import express from "express";
import dotenv from "dotenv";
import cors from "cors"; // import cors
import db from "./config/database.js";

// Import routes
import AuthRoutes from "./routes/AuthRoutes.js";
import UserRoutes from "./routes/UserRoutes.js";
import ProductRoutes from "./routes/ProductRoutes.js";
import OrderRoutes from "./routes/OrderRoutes.js";

dotenv.config();
const app = express();  

app.use(cors()); // aktifkan CORS
app.use(express.json()); // parsing JSON body

// Register routes
app.use("/auth", AuthRoutes);
app.use("/users", UserRoutes);
app.use("/products", ProductRoutes);
app.use("/orders", OrderRoutes);

// Sync DB
db.sync({ alter: true }) // alter: true akan update tabel sesuai model tanpa drop data
  .then(() => console.log("Database synced"))
  .catch((err) => console.error("Error syncing DB:", err));

const PORT = process.env.PORT || 5000;

// bind ke 0.0.0.0 supaya bisa diakses dari device/emulator lain
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
