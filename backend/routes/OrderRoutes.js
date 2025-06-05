import express from "express";
import {
  getOrders,
  getOrderById,
  createOrder,
  updateOrder,
  deleteOrder,
  updateOrderStatus,
  getOrdersByUser, // tambahkan ini
} from "../controllers/OrderController.js";

import { verifyToken, isAdmin } from "../middleware/AuthMiddleware.js";

const router = express.Router();

router.get("/", verifyToken, getOrders);
router.get("/:id", verifyToken, getOrderById);
router.post("/", verifyToken, createOrder);
router.put("/:id", verifyToken, updateOrder);
router.delete("/:id", verifyToken, deleteOrder);
router.patch("/:id/status", verifyToken, isAdmin, updateOrderStatus);

// Route baru untuk history by user
router.get("/user/:userId", verifyToken, getOrdersByUser);

export default router;
