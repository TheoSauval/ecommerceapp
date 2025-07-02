import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  IconButton,
  Tooltip,
  Alert,
  Skeleton,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Avatar,
  Divider,
  Grid,
} from '@mui/material';
import {
  Refresh as RefreshIcon,
  Visibility as VisibilityIcon,
  LocalShipping as ShippingIcon,
  CheckCircle as DeliveredIcon,
  Pending as PendingIcon,
  Cancel as CancelIcon,
  ShoppingCart as CartIcon,
  Close as CloseIcon,
} from '@mui/icons-material';
import { useTheme } from '../context/ThemeContext';
import api from '../config/api';

const Orders = () => {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [statusUpdating, setStatusUpdating] = useState(false);
  const { darkMode } = useTheme();

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    try {
      setLoading(true);
      setError(null);
      const token = localStorage.getItem('token');
      const response = await api.get('/admin/orders', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setOrders(response.data);
    } catch (error) {
      console.error('Error fetching orders:', error);
      setError('Erreur lors du chargement des commandes');
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (orderId, newStatus) => {
    try {
      setStatusUpdating(true);
      setError(null);
      const token = localStorage.getItem('token');
      const response = await api.put(`/admin/orders/${orderId}/status`, 
        { status: newStatus },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      
      // Mettre à jour la liste des commandes
      setOrders(prevOrders => 
        prevOrders.map(order => 
          order.id === orderId 
            ? { ...order, status: newStatus }
            : order
        )
      );
    } catch (error) {
      console.error('Error updating order status:', error);
      // Afficher le message d'erreur spécifique du serveur
      const errorMessage = error.response?.data?.message || 'Erreur lors de la mise à jour du statut';
      setError(errorMessage);
      
      // Effacer l'erreur après 5 secondes
      setTimeout(() => setError(null), 5000);
    } finally {
      setStatusUpdating(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'En attente':
        return 'warning';
      case 'Expédiée':
        return 'info';
      case 'Livrée':
        return 'success';
      case 'Annulée':
        return 'error';
      default:
        return 'default';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'En attente':
        return <PendingIcon />;
      case 'Expédiée':
        return <ShippingIcon />;
      case 'Livrée':
        return <DeliveredIcon />;
      case 'Annulée':
        return <CancelIcon />;
      default:
        return <CartIcon />;
    }
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('fr-FR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const calculateOrderTotal = (items) => {
    return items.reduce((total, item) => total + (item.prix * item.quantite), 0);
  };

  const handleViewOrder = (order) => {
    setSelectedOrder(order);
    setDialogOpen(true);
  };

  if (error) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
        <Box sx={{ display: 'flex', justifyContent: 'center' }}>
          <Tooltip title="Réessayer">
            <IconButton onClick={fetchOrders} size="large">
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 0 }}>
      {error && (
        <Alert 
          severity="error" 
          sx={{ mb: 3 }}
          onClose={() => setError(null)}
          action={
            <IconButton
              color="inherit"
              size="small"
              onClick={() => setError(null)}
            >
              <CloseIcon />
            </IconButton>
          }
        >
          {error}
        </Alert>
      )}
      
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 700, color: 'text.primary' }}>
          Gestion des Commandes
        </Typography>
        <Tooltip title="Actualiser les commandes">
          <span>
            <IconButton onClick={fetchOrders} disabled={loading}>
              <RefreshIcon />
            </IconButton>
          </span>
        </Tooltip>
      </Box>

      <Card sx={{ 
        background: darkMode ? 'linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%)' : 'linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%)',
        border: `1px solid ${darkMode ? '#333' : '#e0e0e0'}`,
      }}>
        <CardContent sx={{ p: 3 }}>
          {loading ? (
            <Box>
              <Skeleton variant="rectangular" height={60} sx={{ mb: 2 }} />
              <Skeleton variant="rectangular" height={400} />
            </Box>
          ) : (
            <TableContainer component={Paper} sx={{ 
              backgroundColor: 'transparent',
              boxShadow: 'none',
              border: `1px solid ${darkMode ? '#333' : '#e0e0e0'}`,
            }}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }}>ID Commande</TableCell>
                    <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }}>Client</TableCell>
                    <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }}>Produits</TableCell>
                    <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }}>Total</TableCell>
                    <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }}>Statut</TableCell>
                    <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }}>Date</TableCell>
                    <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }}>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {orders.map((order) => (
                    <TableRow key={order.id} sx={{ '&:hover': { backgroundColor: darkMode ? '#333' : '#f5f5f5' } }}>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000' }}>
                        #{order.id}
                      </TableCell>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000' }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Avatar sx={{ width: 32, height: 32, bgcolor: 'primary.main' }}>
                            {order.user?.nom?.charAt(0) || 'U'}
                          </Avatar>
                          <Box>
                            <Typography variant="body2" sx={{ fontWeight: 500 }}>
                              {order.user?.nom} {order.user?.prenom}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {order.user?.email || 'Client'}
                            </Typography>
                          </Box>
                        </Box>
                      </TableCell>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000' }}>
                        <Typography variant="body2">
                          {order.items?.length || 0} produit(s)
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {order.items?.map(item => item.nom_produit).join(', ')}
                        </Typography>
                      </TableCell>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000' }}>
                        <Chip 
                          label={`€${calculateOrderTotal(order.items || []).toFixed(2)}`} 
                          color="primary" 
                          size="small"
                          clickable={false}
                          onClick={undefined}
                          onDelete={undefined}
                          sx={{ ml: 1, pointerEvents: 'none' }}
                        />
                      </TableCell>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000' }}>
                        <FormControl size="small" sx={{ minWidth: 120 }}>
                          <Select
                            value={order.status}
                            onChange={(e) => handleStatusChange(order.id, e.target.value)}
                            disabled={statusUpdating}
                            sx={{
                              color: darkMode ? '#fff' : '#000',
                              '& .MuiSelect-icon': {
                                color: darkMode ? '#fff' : '#000',
                              },
                            }}
                          >
                            <MenuItem value="En attente">En attente</MenuItem>
                            <MenuItem value="Expédiée">Expédiée</MenuItem>
                            <MenuItem value="Livrée">Livrée</MenuItem>
                            <MenuItem value="Annulée">Annulée</MenuItem>
                          </Select>
                        </FormControl>
                      </TableCell>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000' }}>
                        <Typography variant="body2">
                          {formatDate(order.date_commande)}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Tooltip title="Voir les détails">
                          <IconButton 
                            size="small" 
                            onClick={() => handleViewOrder(order)}
                            sx={{ color: darkMode ? '#fff' : '#000' }}
                          >
                            <VisibilityIcon />
                          </IconButton>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  ))}
                  {orders.length === 0 && (
                    <TableRow>
                      <TableCell colSpan={7} sx={{ color: darkMode ? '#fff' : '#000', textAlign: 'center', py: 4 }}>
                        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
                          <CartIcon sx={{ fontSize: 48, opacity: 0.5 }} />
                          <Typography variant="h6" color="text.secondary">
                            Aucune commande pour le moment
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            Les commandes de vos clients apparaîtront ici
                          </Typography>
                        </Box>
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>

      {/* Dialog pour voir les détails de la commande */}
      <Dialog 
        open={dialogOpen} 
        onClose={() => setDialogOpen(false)}
        maxWidth="md"
        fullWidth
        PaperProps={{
          sx: {
            background: darkMode ? 'linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%)' : 'linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%)',
            border: `1px solid ${darkMode ? '#333' : '#e0e0e0'}`,
          }
        }}
      >
        <DialogTitle sx={{ color: darkMode ? '#fff' : '#000' }}>
          Détails de la commande #{selectedOrder?.id}
        </DialogTitle>
        <DialogContent>
          {selectedOrder && (
            <Box>
              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <Typography variant="h6" sx={{ mb: 2, color: darkMode ? '#fff' : '#000' }}>
                    Informations client
                  </Typography>
                  <Box sx={{ p: 2, border: `1px solid ${darkMode ? '#333' : '#e0e0e0'}`, borderRadius: 2 }}>
                    <Typography variant="body2" sx={{ mb: 1, color: darkMode ? '#fff' : '#000' }}>
                      <strong>Nom:</strong> {selectedOrder.user?.nom} {selectedOrder.user?.prenom}
                    </Typography>
                    {selectedOrder.user?.email && (
                      <Typography variant="body2" sx={{ color: darkMode ? '#fff' : '#000' }}>
                        <strong>Email:</strong> {selectedOrder.user.email}
                      </Typography>
                    )}
                  </Box>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Typography variant="h6" sx={{ mb: 2, color: darkMode ? '#fff' : '#000' }}>
                    Informations commande
                  </Typography>
                  <Box sx={{ p: 2, border: `1px solid ${darkMode ? '#333' : '#e0e0e0'}`, borderRadius: 2 }}>
                    <Typography variant="body2" sx={{ mb: 1, color: darkMode ? '#fff' : '#000' }}>
                      <strong>Date:</strong> {formatDate(selectedOrder.date_commande)}
                    </Typography>
                    <Typography variant="body2" sx={{ mb: 1, color: darkMode ? '#fff' : '#000' }}>
                      <strong>Statut:</strong> 
                      <Chip 
                        label={selectedOrder.status} 
                        color={getStatusColor(selectedOrder.status)}
                        size="small"
                        icon={getStatusIcon(selectedOrder.status)}
                        clickable={false}
                        onClick={undefined}
                        onDelete={undefined}
                        sx={{ ml: 1, pointerEvents: 'none' }}
                      />
                    </Typography>
                    <Typography variant="body2" sx={{ color: darkMode ? '#fff' : '#000' }}>
                      <strong>Total:</strong> €{calculateOrderTotal(selectedOrder.items || []).toFixed(2)}
                    </Typography>
                  </Box>
                </Grid>
              </Grid>
              
              <Divider sx={{ my: 3, borderColor: darkMode ? '#333' : '#e0e0e0' }} />
              
              <Typography variant="h6" sx={{ mb: 2, color: darkMode ? '#fff' : '#000' }}>
                Produits commandés
              </Typography>
              <TableContainer component={Paper} sx={{ 
                backgroundColor: 'transparent',
                boxShadow: 'none',
                border: `1px solid ${darkMode ? '#333' : '#e0e0e0'}`,
              }}>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }}>Produit</TableCell>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }} align="right">Prix unitaire</TableCell>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }} align="right">Quantité</TableCell>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }} align="right">Total</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {selectedOrder.items?.map((item, index) => (
                      <TableRow key={index}>
                        <TableCell sx={{ color: darkMode ? '#fff' : '#000' }}>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                            <Avatar 
                              variant="rounded" 
                              src={item.image_url} 
                              sx={{ width: 40, height: 40 }}
                            >
                              {!item.image_url && <CartIcon />}
                            </Avatar>
                            <Typography variant="body2">
                              {item.nom_produit}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell sx={{ color: darkMode ? '#fff' : '#000' }} align="right">
                          €{item.prix.toFixed(2)}
                        </TableCell>
                        <TableCell sx={{ color: darkMode ? '#fff' : '#000' }} align="right">
                          {item.quantite}
                        </TableCell>
                        <TableCell sx={{ color: darkMode ? '#fff' : '#000' }} align="right">
                          €{(item.prix * item.quantite).toFixed(2)}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>
            Fermer
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Orders; 