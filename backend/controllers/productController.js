const ProductService = require('../services/ProductService');
const asyncHandler = require('../middleware/asyncHandler');

const formatProduct = (product) => ({
  _id: product._id.toString(),
  name: product.name,
  description: product.description || '',
  price: product.price,
  imageUrl: product.imageUrl || product.image,
  categoryId: product.categoryId ? product.categoryId.toString() : '',
  stock: product.stock ?? 0,
  isActive: product.isActive ?? true,
  rating: product.rating,
  reviewCount: product.reviewCount ?? 0,
  createdAt: product.createdAt,
  updatedAt: product.updatedAt,
});

// Get all products
exports.getAll = asyncHandler(async (req, res, next) => {
  const { page = 1, limit = 10, categoryId } = req.query;
  
  const products = await ProductService.getAllProducts(
    parseInt(page),
    parseInt(limit),
    categoryId
  );

  res.status(200).json({
    success: true,
    data: products.products.map(formatProduct),
    pagination: {
      total: products.total,
      pages: products.pages,
      currentPage: parseInt(page)
    }
  });
});

// Get product by ID
exports.getById = asyncHandler(async (req, res, next) => {
  const product = await ProductService.getProductById(req.params.id);

  res.status(200).json({
    success: true,
    data: formatProduct(product)
  });
});

// Create product
exports.create = asyncHandler(async (req, res, next) => {
  const product = await ProductService.createProduct(req.body);

  res.status(201).json({
    success: true,
    message: 'Product created successfully',
    data: formatProduct(product)
  });
});

// Update product
exports.update = asyncHandler(async (req, res, next) => {
  const product = await ProductService.updateProduct(req.params.id, req.body);

  res.status(200).json({
    success: true,
    message: 'Product updated successfully',
    data: formatProduct(product)
  });
});

// Delete product
exports.delete = asyncHandler(async (req, res, next) => {
  await ProductService.deleteProduct(req.params.id);

  res.status(200).json({
    success: true,
    message: 'Product deleted successfully'
  });
});

// Search products
exports.search = asyncHandler(async (req, res, next) => {
  const { q, page = 1, limit = 10 } = req.query;

  if (!q) {
    return res.status(400).json({
      success: false,
      error: 'Search query is required'
    });
  }

  const products = await ProductService.searchProducts(q, parseInt(page), parseInt(limit));

  res.status(200).json({
    success: true,
    data: products.products,
    pagination: {
      total: products.total,
      pages: products.pages,
      currentPage: parseInt(page)
    }
  });
});
