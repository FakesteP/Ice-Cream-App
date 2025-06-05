import express from "express";
import {
  getProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
} from "../controllers/ProductController.js";

import { verifyToken, isAdmin } from "../middleware/AuthMiddleware.js";

const router = express.Router();

router.get("/", getProducts); // publik
router.get("/:id", getProductById); // publik
router.post("/", verifyToken, isAdmin, createProduct);
router.put("/:id", verifyToken, isAdmin, updateProduct);
router.delete("/:id", verifyToken, isAdmin, deleteProduct);

export default router;
