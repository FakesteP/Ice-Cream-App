import User from "../models/User.js";
import bcrypt from "bcryptjs";

export const getUsers = async (req, res) => {
  try {
    const users = await User.findAll({ attributes: { exclude: ["password"] } });
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const getUserById = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id, {
      attributes: { exclude: ["password"] },
    });
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const createUser = async (req, res) => {
  const { username, email, password, role } = req.body;
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = await User.create({
      username,
      email,
      password: hashedPassword,
      role,
    });
    res.status(201).json({
      id: newUser.id,
      username: newUser.username,
      email: newUser.email,
      role: newUser.role,
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

export const updateUser = async (req, res) => {
  const { username, email, password, role } = req.body;
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ message: "User not found" });

    if (password) user.password = await bcrypt.hash(password, 10);
    if (username) user.username = username;
    if (email) user.email = email;
    if (role) user.role = role;

    await user.save();
    res.json({ message: "User updated" });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

export const deleteUser = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ message: "User not found" });
    await user.destroy();
    res.json({ message: "User deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Upload profile photo (base64 to BLOB)
export const uploadProfilePhoto = async (req, res) => {
  try {
    const { base64Image, mimeType } = req.body;
    const userId = req.params.id;

    if (!base64Image) {
      return res.status(400).json({ message: "No image data provided" });
    }

    // Validate mime type
    const allowedTypes = ["image/jpeg", "image/jpg", "image/png", "image/gif"];
    if (mimeType && !allowedTypes.includes(mimeType)) {
      return res
        .status(400)
        .json({
          message: "Invalid image type. Only JPEG, PNG, and GIF are allowed.",
        });
    }

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Remove data:image/jpeg;base64, prefix if present
    const base64Data = base64Image.replace(/^data:image\/\w+;base64,/, "");

    // Convert base64 to Buffer
    const imageBuffer = Buffer.from(base64Data, "base64");

    // Update user with profile photo
    await user.update({
      profilePhoto: imageBuffer,
      profilePhotoType: mimeType || "image/jpeg",
    });

    res.json({
      message: "Profile photo uploaded successfully",
      photoType: mimeType || "image/jpeg",
      photoSize: imageBuffer.length,
    });
  } catch (error) {
    console.error("Upload profile photo error:", error);
    res.status(500).json({ message: error.message });
  }
};

// Get profile photo (BLOB to base64)
export const getProfilePhoto = async (req, res) => {
  try {
    const userId = req.params.id;

    const user = await User.findByPk(userId, {
      attributes: ["profilePhoto", "profilePhotoType"],
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!user.profilePhoto) {
      return res.status(404).json({ message: "No profile photo found" });
    }

    // Convert BLOB to base64
    const base64Image = user.profilePhoto.toString("base64");
    const mimeType = user.profilePhotoType || "image/jpeg";

    res.json({
      imageData: `data:${mimeType};base64,${base64Image}`,
      mimeType: mimeType,
    });
  } catch (error) {
    console.error("Get profile photo error:", error);
    res.status(500).json({ message: error.message });
  }
};

// Delete profile photo
export const deleteProfilePhoto = async (req, res) => {
  try {
    const userId = req.params.id;

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    await user.update({
      profilePhoto: null,
      profilePhotoType: null,
    });

    res.json({ message: "Profile photo deleted successfully" });
  } catch (error) {
    console.error("Delete profile photo error:", error);
    res.status(500).json({ message: error.message });
  }
};
