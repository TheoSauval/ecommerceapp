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
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Card,
  CardMedia,
  CircularProgress,
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  Add as AddIcon,
  CloudUpload as UploadIcon,
  Close as CloseIcon,
} from '@mui/icons-material';
import { useTheme } from '../context/ThemeContext';
import api from '../config/api';

function Products() {
  const [products, setProducts] = useState([]);
  const [colors, setColors] = useState([]);
  const [heights, setHeights] = useState([]);
  const [open, setOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState(null);
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [previewImages, setPreviewImages] = useState([]);
  const [variantDetailsOpen, setVariantDetailsOpen] = useState(false);
  const [selectedVariant, setSelectedVariant] = useState(null);
  const { darkMode } = useTheme();
  const [formData, setFormData] = useState({
    nom: '',
    description: '',
    prix_base: '',
    marque: '',
    categorie: '',
    images: [],
    variants: []
  });

  useEffect(() => {
    fetchProducts();
    fetchColors();
    fetchHeights();
  }, []);

  const fetchProducts = async () => {
    try {
      setLoading(true);
      const response = await api.get('/admin/products');
      setProducts(response.data);
    } catch (error) {
      console.error('Error fetching products:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchColors = async () => {
    try {
      const response = await api.get('/admin/products/colors');
      setColors(response.data);
    } catch (error) {
      console.error('Error fetching colors:', error);
    }
  };

  const fetchHeights = async () => {
    try {
      const response = await api.get('/admin/products/heights');
      setHeights(response.data);
    } catch (error) {
      console.error('Error fetching heights:', error);
    }
  };

  const handleOpen = (product = null) => {
    if (product) {
      setEditingProduct(product);
      setFormData({
        nom: product.nom,
        description: product.description,
        prix_base: product.prix_base,
        marque: product.marque || '',
        categorie: product.categorie || '',
        images: product.images || [],
        variants: product.variants || []
      });
      setPreviewImages(product.images || []);
    } else {
      setEditingProduct(null);
      setFormData({
        nom: '',
        description: '',
        prix_base: '',
        marque: '',
        categorie: '',
        images: [],
        variants: []
      });
      setPreviewImages([]);
    }
    setSelectedFiles([]);
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
    setEditingProduct(null);
    setSelectedFiles([]);
    setPreviewImages([]);
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleFileSelect = (event) => {
    const files = Array.from(event.target.files);
    setSelectedFiles(files);
    
    // Créer des aperçus
    const newPreviews = files.map(file => URL.createObjectURL(file));
    setPreviewImages(prev => [...prev, ...newPreviews]);
  };

  const removeImage = (index) => {
    setPreviewImages(prev => prev.filter((_, i) => i !== index));
    if (index < formData.images.length) {
      setFormData(prev => ({
        ...prev,
        images: prev.images.filter((_, i) => i !== index)
      }));
    } else {
      setSelectedFiles(prev => prev.filter((_, i) => i !== (index - formData.images.length)));
    }
  };

  const addVariant = () => {
    setFormData(prev => ({
      ...prev,
      variants: [...prev.variants, { color_id: '', height_id: '', stock: 0, prix: '' }]
    }));
  };

  const removeVariant = (index) => {
    setFormData(prev => ({
      ...prev,
      variants: prev.variants.filter((_, i) => i !== index)
    }));
  };

  const updateVariant = (index, field, value) => {
    setFormData(prev => ({
      ...prev,
      variants: prev.variants.map((variant, i) => 
        i === index ? { ...variant, [field]: value } : variant
      )
    }));
  };

  const uploadImages = async () => {
    if (selectedFiles.length === 0) return formData.images;

    setUploading(true);
    try {
      const formDataFiles = new FormData();
      selectedFiles.forEach(file => {
        formDataFiles.append('images', file);
      });

      const response = await api.post('/admin/upload/images', formDataFiles, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      return [...formData.images, ...response.data.urls];
    } catch (error) {
      console.error('Error uploading images:', error);
      throw error;
    } finally {
      setUploading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      setLoading(true);
      
      // Télécharger les images si nécessaire
      let imageUrls = formData.images;
      if (selectedFiles.length > 0) {
        imageUrls = await uploadImages();
      }

      const dataToSend = {
        ...formData,
        prix_base: Number(formData.prix_base),
        images: imageUrls,
        variants: formData.variants.filter(v => v.color_id && v.height_id)
      };

      let product;
      if (editingProduct) {
        const response = await api.put(
          `/admin/products/${editingProduct.id}`,
          dataToSend
        );
        product = response.data;
      } else {
        const response = await api.post(
          '/admin/products',
          dataToSend
        );
        product = response.data;
      }

      handleClose();
      fetchProducts();
    } catch (error) {
      console.error('Error saving product:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce produit ?')) {
      try {
        await api.delete(`/admin/products/${id}`);
        fetchProducts();
      } catch (error) {
        console.error('Error deleting product:', error);
      }
    }
  };

  const handleVariantClick = (variant, product) => {
    setSelectedVariant({ ...variant, product });
    setVariantDetailsOpen(true);
  };

  const handleVariantDetailsClose = () => {
    setVariantDetailsOpen(false);
    setSelectedVariant(null);
  };

  const getTotalStock = (variants) => {
    return variants.reduce((total, variant) => total + (variant.stock || 0), 0);
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h4" sx={{ color: 'text.primary' }}>Produits</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => handleOpen()}
          sx={{
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            '&:hover': {
              background: 'linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%)',
            },
          }}
        >
          Ajouter un produit
        </Button>
      </Box>

      <TableContainer component={Paper} sx={{ 
        background: darkMode ? 'linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%)' : 'linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%)',
        border: `1px solid ${darkMode ? '#333' : '#e0e0e0'}`,
      }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Image</TableCell>
              <TableCell>Nom</TableCell>
              <TableCell>Description</TableCell>
              <TableCell>Prix de base</TableCell>
              <TableCell>Stock total</TableCell>
              <TableCell>Marque</TableCell>
              <TableCell>Catégorie</TableCell>
              <TableCell>Variantes</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {products.map((product) => (
              <TableRow key={product.id}>
                <TableCell>
                  {product.images && product.images.length > 0 && (
                    <img 
                      src={product.images[0]} 
                      alt={product.nom}
                      style={{ width: 50, height: 50, objectFit: 'cover', borderRadius: 4 }}
                    />
                  )}
                </TableCell>
                <TableCell sx={{ color: 'text.primary' }}>{product.nom}</TableCell>
                <TableCell sx={{ color: 'text.primary' }}>{product.description}</TableCell>
                <TableCell sx={{ color: 'text.primary' }}>€{product.prix_base}</TableCell>
                <TableCell sx={{ color: 'text.primary' }}>{getTotalStock(product.variants || [])}</TableCell>
                <TableCell sx={{ color: 'text.primary' }}>{product.marque}</TableCell>
                <TableCell sx={{ color: 'text.primary' }}>{product.categorie}</TableCell>
                <TableCell>
                  <Stack direction="row" spacing={1} flexWrap="wrap">
                    {product.variants?.map((variant, index) => (
                      <Chip 
                        key={index} 
                        label={`${variant.colors?.nom} - ${variant.heights?.nom} (${variant.stock})`} 
                        size="small"
                        onClick={() => handleVariantClick(variant, product)}
                        sx={{ 
                          cursor: 'pointer',
                          '&:hover': {
                            backgroundColor: 'primary.light',
                            color: 'white'
                          }
                        }}
                      />
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
        <DialogTitle sx={{ color: 'text.primary' }}>
          {editingProduct ? 'Modifier le produit' : 'Ajouter un nouveau produit'}
        </DialogTitle>
        <DialogContent>
          <Box component="form" sx={{ mt: 2 }}>
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Nom"
                  name="nom"
                  value={formData.nom}
                  onChange={handleChange}
                  margin="normal"
                  required
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Prix de base (€)"
                  name="prix_base"
                  type="number"
                  value={formData.prix_base}
                  onChange={handleChange}
                  margin="normal"
                  required
                />
              </Grid>
              <Grid item xs={12}>
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
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Marque"
                  name="marque"
                  value={formData.marque}
                  onChange={handleChange}
                  margin="normal"
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Catégorie"
                  name="categorie"
                  value={formData.categorie}
                  onChange={handleChange}
                  margin="normal"
                />
              </Grid>
              
              {/* Section Images */}
              <Grid item xs={12}>
                <Typography variant="h6" sx={{ mt: 2, mb: 1, color: 'text.primary' }}>
                  Images du produit
                </Typography>
                <input
                  accept="image/*"
                  style={{ display: 'none' }}
                  id="image-upload"
                  multiple
                  type="file"
                  onChange={handleFileSelect}
                />
                <label htmlFor="image-upload">
                  <Button
                    variant="outlined"
                    component="span"
                    startIcon={<UploadIcon />}
                    disabled={uploading}
                  >
                    {uploading ? 'Téléchargement...' : 'Sélectionner des images'}
                  </Button>
                </label>
                
                {/* Aperçu des images */}
                <Box sx={{ mt: 2, display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                  {previewImages.map((image, index) => (
                    <Card key={index} sx={{ width: 100, position: 'relative' }}>
                      <CardMedia
                        component="img"
                        height="100"
                        image={image}
                        alt={`Image ${index + 1}`}
                      />
                      <IconButton
                        size="small"
                        sx={{ position: 'absolute', top: 0, right: 0, bgcolor: 'rgba(255,255,255,0.8)' }}
                        onClick={() => removeImage(index)}
                      >
                        <CloseIcon />
                      </IconButton>
                    </Card>
                  ))}
                </Box>
              </Grid>

              {/* Section Variantes */}
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mt: 2 }}>
                  <Typography variant="h6" sx={{ color: 'text.primary' }}>
                    Variantes (Couleur + Taille + Stock)
                  </Typography>
                  <Button onClick={addVariant} variant="outlined" size="small">
                    Ajouter une variante
                  </Button>
                </Box>
                
                {formData.variants.map((variant, index) => (
                  <Card key={index} sx={{ mt: 1, p: 2, background: darkMode ? '#1a1a1a' : '#f8f9fa' }}>
                    <Grid container spacing={2} alignItems="center">
                      <Grid item xs={12} md={3}>
                        <FormControl fullWidth size="small">
                          <InputLabel>Couleur</InputLabel>
                          <Select
                            value={variant.color_id}
                            onChange={(e) => updateVariant(index, 'color_id', e.target.value)}
                            label="Couleur"
                          >
                            {colors.map((color) => (
                              <MenuItem key={color.id} value={color.id}>
                                {color.nom}
                              </MenuItem>
                            ))}
                          </Select>
                        </FormControl>
                      </Grid>
                      <Grid item xs={12} md={3}>
                        <FormControl fullWidth size="small">
                          <InputLabel>Taille</InputLabel>
                          <Select
                            value={variant.height_id}
                            onChange={(e) => updateVariant(index, 'height_id', e.target.value)}
                            label="Taille"
                          >
                            {heights.map((height) => (
                              <MenuItem key={height.id} value={height.id}>
                                {height.nom}
                              </MenuItem>
                            ))}
                          </Select>
                        </FormControl>
                      </Grid>
                      <Grid item xs={12} md={2}>
                        <TextField
                          fullWidth
                          label="Stock"
                          type="number"
                          size="small"
                          value={variant.stock}
                          onChange={(e) => updateVariant(index, 'stock', Number(e.target.value))}
                        />
                      </Grid>
                      <Grid item xs={12} md={2}>
                        <TextField
                          fullWidth
                          label="Prix (optionnel)"
                          type="number"
                          size="small"
                          value={variant.prix}
                          onChange={(e) => updateVariant(index, 'prix', e.target.value ? Number(e.target.value) : null)}
                        />
                      </Grid>
                      <Grid item xs={12} md={2}>
                        <IconButton 
                          onClick={() => removeVariant(index)}
                          color="error"
                          size="small"
                        >
                          <DeleteIcon />
                        </IconButton>
                      </Grid>
                    </Grid>
                  </Card>
                ))}
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose}>Annuler</Button>
          <Button 
            onClick={handleSubmit} 
            variant="contained"
            disabled={loading || uploading}
            sx={{
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              '&:hover': {
                background: 'linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%)',
              },
            }}
          >
            {loading ? 'Enregistrement...' : (editingProduct ? 'Sauvegarder' : 'Ajouter')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialogue de détails des variantes */}
      <Dialog open={variantDetailsOpen} onClose={handleVariantDetailsClose} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ color: 'text.primary' }}>
          Détails de la variante
        </DialogTitle>
        <DialogContent>
          {selectedVariant && (
            <Box sx={{ mt: 2 }}>
              <Typography variant="h6" gutterBottom sx={{ color: 'text.primary' }}>
                {selectedVariant.product?.nom}
              </Typography>
              
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Couleur
                  </Typography>
                  <Typography variant="body1" sx={{ color: 'text.primary' }}>
                    {selectedVariant.colors?.nom}
                  </Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Taille
                  </Typography>
                  <Typography variant="body1" sx={{ color: 'text.primary' }}>
                    {selectedVariant.heights?.nom}
                  </Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Stock disponible
                  </Typography>
                  <Typography variant="body1" sx={{ 
                    color: selectedVariant.stock > 0 ? 'success.main' : 'error.main',
                    fontWeight: 'bold'
                  }}>
                    {selectedVariant.stock} unités
                  </Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Prix de base du produit
                  </Typography>
                  <Typography variant="body1" sx={{ color: 'text.primary' }}>
                    €{selectedVariant.product?.prix_base}
                  </Typography>
                </Grid>
                
                {selectedVariant.prix && (
                  <Grid item xs={12}>
                    <Typography variant="subtitle2" color="text.secondary">
                      Prix spécifique de cette variante
                    </Typography>
                    <Typography variant="h6" color="primary.main">
                      €{selectedVariant.prix}
                    </Typography>
                  </Grid>
                )}
                
                <Grid item xs={12}>
                  <Typography variant="subtitle2" color="text.secondary">
                    Statut
                  </Typography>
                  <Chip 
                    label={selectedVariant.actif ? 'Active' : 'Inactive'} 
                    color={selectedVariant.actif ? 'success' : 'default'}
                    size="small"
                  />
                </Grid>
              </Grid>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleVariantDetailsClose}>Fermer</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

export default Products; 