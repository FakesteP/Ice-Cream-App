import express from "express";
import {
  getUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
} from "../controllers/UserController.js";

import { verifyToken, isAdmin } from "../middleware/AuthMiddleware.js";

const router = express.Router();

router.get("/", verifyToken, isAdmin, getUsers);
router.get("/:id", verifyToken, getUserById);
router.post("/", verifyToken, isAdmin, createUser);
router.put("/:id", verifyToken, updateUser);
router.delete("/:id", verifyToken, isAdmin, deleteUser);

export default router;
