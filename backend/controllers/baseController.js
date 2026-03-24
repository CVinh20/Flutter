const asyncHandler = require('../middleware/asyncHandler');

// Generic CRUD operations
const createBaseController = (Model, modelName) => {
  return {
    // @desc    Get all items
    // @route   GET /api/{modelName}
    // @access  Public
    getAll: asyncHandler(async (req, res) => {
      const page = parseInt(req.query.page, 10) || 1;
      const limit = parseInt(req.query.limit, 10) || 10;
      const startIndex = (page - 1) * limit;

      // Build query
      let query = Model.find();

      // Apply filters if provided
      if (req.query.search) {
        const searchRegex = new RegExp(req.query.search, 'i');
        query = query.or([
          { name: searchRegex },
          { title: searchRegex },
          { description: searchRegex }
        ]);
      }

      // Apply sorting
      if (req.query.sort) {
        const sortBy = req.query.sort.split(',').join(' ');
        query = query.sort(sortBy);
      } else {
        query = query.sort('-createdAt');
      }

      // Execute query with pagination
      const items = await query.skip(startIndex).limit(limit);
      const total = await Model.countDocuments(query.getQuery());

      res.status(200).json({
        success: true,
        count: items.length,
        total,
        pagination: {
          page,
          limit,
          pages: Math.ceil(total / limit)
        },
        data: items
      });
    }),

    // @desc    Get single item
    // @route   GET /api/{modelName}/:id
    // @access  Public
    getById: asyncHandler(async (req, res) => {
      const item = await Model.findById(req.params.id);

      if (!item) {
        return res.status(404).json({
          success: false,
          error: `${modelName} not found`
        });
      }

      res.status(200).json({
        success: true,
        data: item
      });
    }),

    // @desc    Create new item
    // @route   POST /api/{modelName}
    // @access  Private
    create: asyncHandler(async (req, res) => {
      const item = await Model.create(req.body);

      res.status(201).json({
        success: true,
        data: item
      });
    }),

    // @desc    Update item
    // @route   PUT /api/{modelName}/:id
    // @access  Private
    update: asyncHandler(async (req, res) => {
      console.log(`📝 Updating ${modelName} ${req.params.id} with:`, req.body);
      
      try {
        const item = await Model.findByIdAndUpdate(
          req.params.id,
          req.body,
          {
            new: true,
            runValidators: true
          }
        );

        if (!item) {
          return res.status(404).json({
            success: false,
            error: `${modelName} not found`
          });
        }

        res.status(200).json({
          success: true,
          data: item
        });
      } catch (error) {
        console.error(`❌ Error updating ${modelName}:`, error.message);
        return res.status(400).json({
          success: false,
          error: error.message || `Failed to update ${modelName}`
        });
      }
    }),

    // @desc    Delete item
    // @route   DELETE /api/{modelName}/:id
    // @access  Private
    delete: asyncHandler(async (req, res) => {
      const item = await Model.findByIdAndDelete(req.params.id);

      if (!item) {
        return res.status(404).json({
          success: false,
          error: `${modelName} not found`
        });
      }

      res.status(200).json({
        success: true,
        data: {}
      });
    })
  };
};

module.exports = createBaseController;
