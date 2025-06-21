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
} from '@mui/material';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  ResponsiveContainer,
} from 'recharts';
import {
  AttachMoney as MoneyIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { useTheme } from '../context/ThemeContext';
import api from '../config/api';

const Dashboard = () => {
  const [salesData, setSalesData] = useState({
    totalRevenue: 0,
    salesByMonth: {},
  });
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
      const response = await api.get('/admin/dashboard/sales', {
        headers: { Authorization: `Bearer ${token}` }
      });

      setSalesData(response.data);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
      setError('Erreur lors du chargement des données du dashboard');
    } finally {
      setLoading(false);
    }
  };

  const monthlyData = Object.entries(salesData.salesByMonth).map(([month, revenue]) => ({
    month,
    revenue: parseFloat(revenue.toFixed(2)),
  }));

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
          Dashboard
        </Typography>
      </Box>
      
      <Grid container spacing={3}>
        {/* Carte des revenus totaux */}
        <Grid item xs={12} md={4}>
          <StatCard
            title="Revenu Total"
            value={`€${salesData.totalRevenue.toFixed(2)}`}
            icon={<MoneyIcon />}
            color="success"
            subtitle="Toutes les ventes confondues"
          />
        </Grid>

        {/* Graphique des ventes mensuelles */}
        <Grid item xs={12} md={8}>
          <Card sx={{ 
            height: 400,
            background: darkMode ? 'linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%)' : 'linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%)',
            border: `1px solid ${darkMode ? '#333' : '#e0e0e0'}`,
          }}>
            <CardContent sx={{ p: 3, height: '100%' }}>
              <Typography variant="h6" sx={{ mb: 3, fontWeight: 600, color: 'text.primary' }}>
                Ventes Mensuelles
              </Typography>
              {loading ? (
                <Skeleton variant="rectangular" height={300} />
              ) : (
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={monthlyData}>
                    <CartesianGrid strokeDasharray="3 3" stroke={darkMode ? '#333' : '#e0e0e0'} />
                    <XAxis 
                      dataKey="month" 
                      stroke={darkMode ? '#fff' : '#666'}
                      tick={{ fill: darkMode ? '#fff' : '#666' }}
                    />
                    <YAxis 
                      stroke={darkMode ? '#fff' : '#666'}
                      tick={{ fill: darkMode ? '#fff' : '#666' }}
                    />
                    <RechartsTooltip 
                      contentStyle={{
                        backgroundColor: darkMode ? '#2d2d2d' : '#fff',
                        border: `1px solid ${darkMode ? '#333' : '#e0e0e0'}`,
                        borderRadius: 8,
                        color: darkMode ? '#fff' : '#000',
                      }}
                    />
                    <Line
                      type="monotone"
                      dataKey="revenue"
                      stroke="#2196f3"
                      strokeWidth={3}
                      dot={{ fill: '#2196f3', strokeWidth: 2, r: 4 }}
                      activeDot={{ r: 6, stroke: '#2196f3', strokeWidth: 2 }}
                      name="Revenus (€)"
                    />
                  </LineChart>
                </ResponsiveContainer>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard; 