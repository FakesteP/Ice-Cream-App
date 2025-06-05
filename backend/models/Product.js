import { Sequelize } from "sequelize";
import db from "../config/database.js";

const Product = db.define(
  "products",
  {
    id: {
      type: Sequelize.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    name: {
      type: Sequelize.STRING,
      allowNull: false,
    },
    description: {
      type: Sequelize.STRING,
    },
    price: {
      type: Sequelize.FLOAT,
      allowNull: false,
    },
    stock: {
      type: Sequelize.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    imageUrl: {
      type: Sequelize.STRING,
    },
  },
  {
    freezeTableName: true,
    createdAt: "tanggal_dibuat",
    updatedAt: "tanggal_diperbarui",
  }
);

export default Product;
