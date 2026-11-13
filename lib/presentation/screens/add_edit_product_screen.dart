import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils.dart';
import '../../data/model/product_model.dart';
import '../../providers/product_provider.dart';
import '../widgets/product_image.dart';

/// One form for both adding a new product and editing an existing one.
class AddEditProductScreen extends StatefulWidget {
  /// null = add a new product, otherwise edit this product.
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageController;
  late final List<String> _categories;
  String? _category;
  bool _isSaving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _titleController = TextEditingController(text: product?.title);
    _descriptionController = TextEditingController(text: product?.description);
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(2),
    );
    _imageController = TextEditingController(text: product?.mainImage);
    _category = product?.category;

    _categories = List.of(context.read<ProductProvider>().categories);
    if (_category != null &&
        _category!.isNotEmpty &&
        !_categories.contains(_category)) {
      _categories.add(_category!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  // ---------- Validators ----------

  String? _validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Title is required';
    if (text.length < 3) return 'Title must be at least 3 characters';
    return null;
  }

  String? _validateDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Description is required';
    if (text.length < 10) return 'Description must be at least 10 characters';
    return null;
  }

  String? _validatePrice(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Price is required';
    final price = double.tryParse(text);
    if (price == null) return 'Enter a valid number';
    if (price <= 0) return 'Price must be greater than 0';
    return null;
  }

  String? _validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) return 'Category is required';
    return null;
  }

  /// Image URL is optional, but if given it must be a web link.
  String? _validateImageUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    final isWebLink = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return isWebLink ? null : 'Enter a valid http/https image URL';
  }

  // ---------- Save ----------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final provider = context.read<ProductProvider>();
    final imageUrl = _imageController.text.trim();
    final images = imageUrl.isEmpty ? <String>[] : [imageUrl];

    try {
      if (_isEditing) {
        final original = widget.product!;
        final imageChanged = imageUrl != original.mainImage;
        final updated = await provider.updateProduct(
          original.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            price: double.parse(_priceController.text.trim()),
            category: _category!.trim(),
            thumbnail: imageUrl,
            images: imageChanged ? images : null,
          ),
        );
        if (!mounted) return;
        AppUtils.showSnackBar(context, 'Product updated successfully');
        Navigator.of(context).pop(updated);
      } else {
        await provider.addProduct(
          Product(
            id: 0, // the repository gives it a unique local id
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            price: double.parse(_priceController.text.trim()),
            category: _category!.trim(),
            thumbnail: imageUrl,
            images: images,
          ),
        );
        if (!mounted) return;
        AppUtils.showSnackBar(context, 'Product added successfully');
        Navigator.of(context).pop();
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppUtils.showSnackBar(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ImagePreview(controller: _imageController),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: _validateTitle,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  validator: _validateDescription,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _priceController,
                  textInputAction: TextInputAction.next,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price (\$) *',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                  validator: _validatePrice,
                ),
                const SizedBox(height: 14),
                _buildCategoryField(),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _imageController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  validator: _validateImageUrl,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_isEditing
                          ? Icons.save_rounded
                          : Icons.add_rounded),
                  label: Text(_isEditing ? 'Save Changes' : 'Add Product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dropdown when categories are loaded, a text field otherwise.
  Widget _buildCategoryField() {
    const decoration = InputDecoration(
      labelText: 'Category *',
      prefixIcon: Icon(Icons.category_rounded),
    );

    if (_categories.isEmpty) {
      return TextFormField(
        initialValue: _category,
        decoration: decoration,
        onChanged: (value) => _category = value,
        validator: _validateCategory,
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: decoration,
      isExpanded: true,
      items: [
        for (final category in _categories)
          DropdownMenuItem(
            value: category,
            child: Text(AppUtils.prettify(category)),
          ),
      ],
      onChanged: (value) => setState(() => _category = value),
      validator: _validateCategory,
    );
  }
}

/// Live preview of the image URL typed in the form.
class _ImagePreview extends StatelessWidget {
  final TextEditingController controller;

  const _ImagePreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 180,
            child: ProductImage(url: value.text.trim(), fit: BoxFit.contain),
          ),
        );
      },
    );
  }
}
