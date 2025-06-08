import Product from "../models/Product.js";
import User from "../models/User.js";
import Order from "../models/Order.js";

export const getOrders = async (req, res) => {
  try {
    const orders = await Order.findAll({
      include: [
        { model: User, attributes: ["id", "username", "email"] },
        { model: Product },
      ],
      order: [["tanggal_dibuat", "DESC"]],
    });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const getOrderById = async (req, res) => {
  try {
    const order = await Order.findByPk(req.params.id, {
      include: [
        { model: User, attributes: ["id", "username", "email"] },
        { model: Product },
      ],
    });
    if (!order) return res.status(404).json({ message: "Order not found" });
    res.json(order);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const createOrder = async (req, res) => {
  const { userId, productId, quantity } = req.body;
  try {
    const product = await Product.findByPk(productId);
    if (!product) return res.status(404).json({ message: "Product not found" });
    if (product.stock < quantity)
      return res.status(400).json({ message: "Stock not enough" });

    const totalPrice = product.price * quantity;

    const newOrder = await Order.create({
      userId,
      productId,
      quantity,
      totalPrice,
      status: "pending",
    });

    product.stock -= quantity;
    await product.save();

    res.status(201).json(newOrder);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

export const updateOrder = async (req, res) => {
  const { quantity, status } = req.body;
  try {
    const order = await Order.findByPk(req.params.id);
    if (!order) return res.status(404).json({ message: "Order not found" });

    if (quantity !== undefined) {
      const product = await Product.findByPk(order.productId);
      const qtyDiff = quantity - order.quantity;
      if (qtyDiff > 0 && product.stock < qtyDiff)
        return res.status(400).json({ message: "Stock not enough" });

      product.stock -= qtyDiff;
      await product.save();

      order.quantity = quantity;
      order.totalPrice = order.quantity * product.price;
    }

    if (status) order.status = status;

    await order.save();
    res.json({ message: "Order updated" });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

export const deleteOrder = async (req, res) => {
  try {
    const order = await Order.findByPk(req.params.id);
    if (!order) return res.status(404).json({ message: "Order not found" });

    const product = await Product.findByPk(order.productId);
    product.stock += order.quantity;
    await product.save();

    await order.destroy();
    res.json({ message: "Order deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const updateOrderStatus = async (req, res) => {
  const { id } = req.params; // Order ID
  const { status } = req.body; // New status

  try {
    const order = await Order.findByPk(id);
    if (!order) return res.status(404).json({ message: "Order not found" });

    order.status = status;
    await order.save();

    res.json({ message: "Order status updated successfully", order });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const getOrdersByUser = async (req, res) => {
  try {
    const userId = req.params.userId;
    console.log("🔍 Getting orders for user:", userId);

    const orders = await Order.findAll({
      where: { userId },
      include: [{ model: Product }],
      order: [["tanggal_dibuat", "DESC"]],
    });
    console.log(
      "📦 Raw orders from database:",
      JSON.stringify(orders, null, 2)
    );

    // Return raw Sequelize objects like the admin endpoint does
    // This ensures consistency and avoids field mapping errors
    res.json(orders);
  } catch (error) {
    console.error("❌ Error in getOrdersByUser:", error);
    res.status(500).json({ message: error.message });
  }
};
