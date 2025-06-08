import { Sequelize } from "sequelize";
import db from "../config/database.js";

const User = db.define(
  "users",
  {
    id: {
      type: Sequelize.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    username: {
      type: Sequelize.STRING,
      allowNull: false,
      unique: true,
    },
    email: {
      type: Sequelize.STRING,
      allowNull: false,
      unique: true,
      validate: { isEmail: true },
    },
    password: {
      type: Sequelize.STRING,
      allowNull: false,
    },
    role: {
      type: Sequelize.STRING,
      allowNull: false,
      validate: { isIn: [["admin", "customer"]] },
    },
    profilePhoto: {
      type: Sequelize.BLOB("long"),
      allowNull: true,
    },
    profilePhotoType: {
      type: Sequelize.STRING,
      allowNull: true,
      comment: "MIME type of the profile photo (e.g., image/jpeg, image/png)",
    },
  },
  {
    freezeTableName: true,
    createdAt: "tanggal_dibuat",
    updatedAt: "tanggal_diperbarui",
  }
);

export default User;
