import express from "express";
import {
  getUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  uploadProfilePhoto,
  getProfilePhoto,
  deleteProfilePhoto,
} from "../controllers/UserController.js";

import { verifyToken, isAdmin } from "../middleware/AuthMiddleware.js";

const router = express.Router();

router.get("/", verifyToken, isAdmin, getUsers);
router.get("/:id", verifyToken, getUserById);
router.post("/", verifyToken, isAdmin, createUser);
router.put("/:id", verifyToken, updateUser);
router.delete("/:id", verifyToken, isAdmin, deleteUser);

// Profile photo routes
router.post("/:id/profile-photo", verifyToken, uploadProfilePhoto);
router.get("/:id/profile-photo", verifyToken, getProfilePhoto);
router.delete("/:id/profile-photo", verifyToken, deleteProfilePhoto);

export default router;
