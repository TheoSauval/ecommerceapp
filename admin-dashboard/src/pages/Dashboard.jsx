import React, { useState, useEffect } from 'react';
import {
  Grid,
  Typography,
  Box,
  Card,
  CardContent,
  Skeleton,
  Alert,
  IconButton,
  Tooltip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Avatar,
} from '@mui/material';
import {
  Star as StarIcon,
  AttachMoney as MoneyIcon,
  Refresh as RefreshIcon,
  TrendingUp as TrendingUpIcon,
  ShoppingCart as ShoppingCartIcon,
  Image as ImageIcon,
} from '@mui/icons-material';
import { useTheme } from '../context/ThemeContext';
import api from '../config/api';

const Dashboard = () => {
  const [dashboard, setDashboard] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const { darkMode } = useTheme();

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);
      const token = localStorage.getItem('token');
      const response = await api.get('/vendor-analytics/my-dashboard', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setDashboard(response.data.data);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
      setError('Erreur lors du chargement des données du dashboard');
    } finally {
      setLoading(false);
    }
  };

  const StatCard = ({ title, value, icon, color, subtitle }) => (
    <Card sx={{ 
      height: '100%',
      background: darkMode ? 'linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%)' : 'linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%)',
      border: `1px solid ${darkMode ? '#333' : '#e0e0e0'}`,
      transition: 'all 0.3s ease',
      '&:hover': {
        transform: 'translateY(-4px)',
        boxShadow: darkMode 
          ? '0 8px 25px rgba(0, 0, 0, 0.3)' 
          : '0 8px 25px rgba(0, 0, 0, 0.1)',
      }
    }}>
      <CardContent sx={{ p: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
          <Box sx={{ 
            p: 1.5, 
            borderRadius: 2, 
            backgroundColor: `${color}.light`,
            color: `${color}.main`,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            {icon}
          </Box>
          <Tooltip title="Actualiser les données">
            <IconButton size="small" onClick={fetchData} disabled={loading}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        </Box>
        <Typography variant="h4" sx={{ fontWeight: 700, mb: 1 }}>
          {loading ? <Skeleton width="60%" /> : value}
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
          {title}
        </Typography>
        {subtitle && (
          <Typography variant="caption" color="text.secondary">
            {subtitle}
          </Typography>
        )}
      </CardContent>
    </Card>
  );

  if (error) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
        <Box sx={{ display: 'flex', justifyContent: 'center' }}>
          <Tooltip title="Réessayer">
            <IconButton onClick={fetchData} size="large">
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 0 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4}}>
        <Typography variant="h4" sx={{ fontWeight: 700, color: 'text.primary'}}>
          Mon Dashboard Vendeur
        </Typography>
      </Box>
      <Grid container spacing={3}>
        {/* Carte des revenus totaux */}
        <Grid item xs={12} md={4}>
          <StatCard
            title="Revenu Total"
            value={`€${dashboard?.revenue?.total_revenue?.toFixed(2) || '0.00'}`}
            icon={<MoneyIcon />}
            color="success"
            subtitle="Toutes mes ventes"
          />
        </Grid>
        {/* Carte du nombre de produits vendus */}
        <Grid item xs={12} md={4}>
          <StatCard
            title="Produits Vendus"
            value={dashboard?.revenue?.total_products_sold || 0}
            icon={<TrendingUpIcon />}
            color="info"
            subtitle="Quantité totale vendue"
          />
        </Grid>
        {/* Carte du nombre de commandes */}
        <Grid item xs={12} md={4}>
          <StatCard
            title="Commandes"
            value={dashboard?.revenue?.total_orders || 0}
            icon={<ShoppingCartIcon />}
            color="primary"
            subtitle="Nombre total de commandes"
          />
        </Grid>
      </Grid>
      {/* Tableau des top-produits */}
      <Box sx={{ mt: 5 }}>
        <Card sx={{ 
          background: darkMode ? 'linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%)' : 'linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%)',
          border: `1px solid ${darkMode ? '#333' : '#e0e0e0'}`,
        }}>
          <CardContent sx={{ p: 3 }}>
            <Typography variant="h6" sx={{ mb: 3, fontWeight: 600, color: 'text.primary' }}>
              Mes Top-Produits
            </Typography>
            {loading ? (
              <Skeleton variant="rectangular" height={200} />
            ) : (
              <TableContainer component={Paper} sx={{ 
                backgroundColor: 'transparent',
                boxShadow: 'none',
                border: `1px solid ${darkMode ? '#333' : '#e0e0e0'}`,
              }}>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600, width: '10%' }}></TableCell>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }}>Produit</TableCell>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }} align="right">Quantité</TableCell>
                      <TableCell sx={{ color: darkMode ? '#fff' : '#000', fontWeight: 600 }} align="right">Revenus</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {dashboard?.topProducts?.map((product, index) => {
                      const imageUrl = product.product_images && product.product_images.length > 0 ? product.product_images[0] : null;
                      return (
                        <TableRow key={product.product_id} sx={{ '&:hover': { backgroundColor: darkMode ? '#333' : '#f5f5f5' } }}>
                          <TableCell>
                            <Avatar 
                              variant="rounded" 
                              src={imageUrl} 
                              sx={{ width: 56, height: 56, bgcolor: 'grey.700' }}
                            >
                              {!imageUrl && <ImageIcon />}
                            </Avatar>
                          </TableCell>
                          <TableCell sx={{ color: darkMode ? '#fff' : '#000' }}>
                            <Box sx={{ display: 'flex', alignItems: 'center' }}>
                              <StarIcon sx={{ mr: 1, color: index < 3 ? '#ffd700' : '#ccc' }} />
                              {product.product_name}
                            </Box>
                          </TableCell>
                          <TableCell sx={{ color: darkMode ? '#fff' : '#000' }} align="right">
                            {product.total_quantity}
                          </TableCell>
                          <TableCell sx={{ color: darkMode ? '#fff' : '#000' }} align="right">
                            <Chip 
                              label={`€${product.total_revenue.toFixed(2)}`} 
                              color="primary" 
                              size="small"
                            />
                          </TableCell>
                        </TableRow>
                      );
                    })}
                    {dashboard?.topProducts?.length === 0 && (
                      <TableRow>
                        <TableCell colSpan={4} sx={{ color: darkMode ? '#fff' : '#000', textAlign: 'center' }}>
                          Aucun produit vendu pour le moment
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </TableContainer>
            )}
          </CardContent>
        </Card>
      </Box>
    </Box>
  );
};

export default Dashboard; 