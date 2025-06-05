import { Sequelize } from "sequelize";
import db from "../config/database.js";
import User from "./User.js";
import Product from "./Product.js";

const Order = db.define("orders", {
  id: {
    type: Sequelize.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  userId: {
    type: Sequelize.INTEGER,
    allowNull: false,
  },
  productId: {
    type: Sequelize.INTEGER,
    allowNull: false,
  },
  quantity: {
    type: Sequelize.INTEGER,
    allowNull: false,
  },
  totalPrice: {
    type: Sequelize.FLOAT,
    allowNull: false,
  },
  status: {
    type: Sequelize.STRING,
    allowNull: false,
    defaultValue: "pending",
    validate: {
      isIn: [["pending", "processed", "completed", "cancelled"]],
    },
  },
}, {
  freezeTableName: true,
  createdAt: "tanggal_dibuat",
  updatedAt: "tanggal_diperbarui",
});

// Associations
Order.belongsTo(User, { foreignKey: "userId" });
Order.belongsTo(Product, { foreignKey: "productId" });

export default Order;
