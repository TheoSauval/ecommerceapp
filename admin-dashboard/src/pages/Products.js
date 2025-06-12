import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Typography,
  Chip,
  Stack,
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  Add as AddIcon,
} from '@mui/icons-material';
import axios from 'axios';

function Products() {
  const [products, setProducts] = useState([]);
  const [open, setOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState(null);
  const [formData, setFormData] = useState({
    nom: '',
    description: '',
    prix: '',
    quantite: '',
    images: '',
    marque: '',
    categorie: '',
    colors: '',
    heights: '',
  });

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get('http://localhost:3000/api/products', {
        headers: { Authorization: `Bearer ${token}` }
      });
      console.log('API response:', response.data);
      if (Array.isArray(response.data)) {
        setProducts(response.data);
      } else if (Array.isArray(response.data.products)) {
        setProducts(response.data.products);
      } else if (Array.isArray(response.data.rows)) {
        setProducts(response.data.rows);
      } else {
        setProducts([]);
      }
    } catch (error) {
      console.error('Error fetching products:', error);
    }
  };

  const handleOpen = (product = null) => {
    if (product) {
      setEditingProduct(product);
      setFormData({
        nom: product.nom,
        description: product.description,
        prix: product.prix,
        quantite: product.quantite,
        images: Array.isArray(product.images) ? product.images.join(',') : (product.images || ''),
        marque: product.marque || '',
        categorie: product.categorie || '',
        colors: product.colors ? product.colors.map(c => c.couleur).join(',') : '',
        heights: product.heights ? product.heights.map(h => h.taille).join(',') : '',
      });
    } else {
      setEditingProduct(null);
      setFormData({
        nom: '',
        description: '',
        prix: '',
        quantite: '',
        images: '',
        marque: '',
        categorie: '',
        colors: '',
        heights: '',
      });
    }
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
    setEditingProduct(null);
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const token = localStorage.getItem('token');
      if (!token) {
        alert('Vous devez être connecté pour ajouter ou modifier un produit.');
        return;
      }
      console.log('Token utilisé pour la requête:', token);
      const dataToSend = {
        ...formData,
        prix: Number(formData.prix),
        quantite: Number(formData.quantite),
        images: formData.images
          ? formData.images.split(',').map((img) => img.trim()).filter(Boolean)
          : [],
      };
      console.log("Données envoyées à l'API:", dataToSend);
      let product;
      if (editingProduct) {
        const response = await axios.put(
          `http://localhost:3000/api/products/${editingProduct.id}`,
          dataToSend,
          { headers: { Authorization: `Bearer ${token}` } }
        );
        product = response.data;
      } else {
        const response = await axios.post(
          'http://localhost:3000/api/admin/products',
          dataToSend,
          { headers: { Authorization: `Bearer ${token}` } }
        );
        product = response.data;
      }

      // Add colors
      if (formData.colors) {
        const colors = formData.colors.split(',').map(c => c.trim()).filter(Boolean);
        for (const color of colors) {
          await axios.post(
            `http://localhost:3000/api/admin/products/${product.id}/colors`,
            { couleur: color },
            { headers: { Authorization: `Bearer ${token}` } }
          );
        }
      }

      // Add heights
      if (formData.heights) {
        const heights = formData.heights.split(',').map(h => h.trim()).filter(Boolean);
        for (const height of heights) {
          await axios.post(
            `http://localhost:3000/api/admin/products/${product.id}/heights`,
            { hauteur: height },
            { headers: { Authorization: `Bearer ${token}` } }
          );
        }
      }

      handleClose();
      fetchProducts();
    } catch (error) {
      console.error('Error saving product:', error);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this product?')) {
      try {
        const token = localStorage.getItem('token');
        await axios.delete(`http://localhost:3000/api/products/${id}`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        fetchProducts();
      } catch (error) {
        console.error('Error deleting product:', error);
      }
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h4">Products</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => handleOpen()}
        >
          Add Product
        </Button>
      </Box>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Description</TableCell>
              <TableCell>Price</TableCell>
              <TableCell>Stock</TableCell>
              <TableCell>Brand</TableCell>
              <TableCell>Category</TableCell>
              <TableCell>Colors</TableCell>
              <TableCell>Sizes</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {Array.isArray(products) && products.map((product) => (
              <TableRow key={product.id}>
                <TableCell>{product.nom}</TableCell>
                <TableCell>{product.description}</TableCell>
                <TableCell>${product.prix}</TableCell>
                <TableCell>{product.quantite}</TableCell>
                <TableCell>{product.marque}</TableCell>
                <TableCell>{product.categorie}</TableCell>
                <TableCell>
                  <Stack direction="row" spacing={1}>
                    {product.colors?.map((color) => (
                      <Chip key={color.id} label={color.couleur} size="small" />
                    ))}
                  </Stack>
                </TableCell>
                <TableCell>
                  <Stack direction="row" spacing={1}>
                    {product.heights?.map((height) => (
                      <Chip key={height.id} label={height.taille} size="small" />
                    ))}
                  </Stack>
                </TableCell>
                <TableCell>
                  <IconButton onClick={() => handleOpen(product)}>
                    <EditIcon />
                  </IconButton>
                  <IconButton onClick={() => handleDelete(product.id)}>
                    <DeleteIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
        <DialogTitle>
          {editingProduct ? 'Edit Product' : 'Add New Product'}
        </DialogTitle>
        <DialogContent>
          <Box component="form" sx={{ mt: 2 }}>
            <TextField
              fullWidth
              label="Name"
              name="nom"
              value={formData.nom}
              onChange={handleChange}
              margin="normal"
            />
            <TextField
              fullWidth
              label="Description"
              name="description"
              value={formData.description}
              onChange={handleChange}
              margin="normal"
              multiline
              rows={4}
            />
            <TextField
              fullWidth
              label="Price"
              name="prix"
              type="number"
              value={formData.prix}
              onChange={handleChange}
              margin="normal"
            />
            <TextField
              fullWidth
              label="Stock"
              name="quantite"
              type="number"
              value={formData.quantite}
              onChange={handleChange}
              margin="normal"
            />
            <TextField
              fullWidth
              label="Brand"
              name="marque"
              value={formData.marque}
              onChange={handleChange}
              margin="normal"
            />
            <TextField
              fullWidth
              label="Category"
              name="categorie"
              value={formData.categorie}
              onChange={handleChange}
              margin="normal"
            />
            <TextField
              fullWidth
              label="Image URLs (comma-separated)"
              name="images"
              value={formData.images}
              onChange={handleChange}
              margin="normal"
            />
            <TextField
              fullWidth
              label="Colors (comma-separated)"
              name="colors"
              value={formData.colors}
              onChange={handleChange}
              margin="normal"
              helperText="Enter colors separated by commas (e.g., red, blue, green)"
            />
            <TextField
              fullWidth
              label="Sizes (comma-separated)"
              name="heights"
              value={formData.heights}
              onChange={handleChange}
              margin="normal"
              helperText="Enter sizes separated by commas (e.g., S, M, L, XL)"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose}>Cancel</Button>
          <Button onClick={handleSubmit} variant="contained">
            {editingProduct ? 'Save' : 'Add'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

export default Products; 