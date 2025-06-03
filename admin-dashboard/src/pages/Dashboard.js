import React, { useState, useEffect } from 'react';
import {
  Grid,
  Paper,
  Typography,
  Box,
} from '@mui/material';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import axios from 'axios';

function Dashboard() {
  const [salesData, setSalesData] = useState({
    totalRevenue: 0,
    salesByDay: {},
    salesByMonth: {},
  });
  const [topProducts, setTopProducts] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const token = localStorage.getItem('token');
        const [salesResponse, productsResponse] = await Promise.all([
          axios.get('http://localhost:3000/api/admin/dashboard/sales', {
            headers: { Authorization: `Bearer ${token}` }
          }),
          axios.get('http://localhost:3000/api/admin/dashboard/top-products', {
            headers: { Authorization: `Bearer ${token}` }
          })
        ]);

        setSalesData(salesResponse.data);
        setTopProducts(productsResponse.data);
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
      }
    };

    fetchData();
  }, []);

  const monthlyData = Object.entries(salesData.salesByMonth).map(([month, revenue]) => ({
    month,
    revenue,
  }));

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>
      
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Total Revenue
            </Typography>
            <Typography variant="h4">
              ${salesData.totalRevenue.toFixed(2)}
            </Typography>
          </Paper>
        </Grid>

        <Grid item xs={12}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Monthly Sales
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={monthlyData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="revenue"
                  stroke="#8884d8"
                  name="Revenue"
                />
              </LineChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        <Grid item xs={12}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Top Products
            </Typography>
            <Grid container spacing={2}>
              {topProducts.map((product) => (
                <Grid item xs={12} sm={6} md={4} key={product.id}>
                  <Paper sx={{ p: 2 }}>
                    <Typography variant="subtitle1">{product.name}</Typography>
                    <Typography variant="body2">Price: ${product.price}</Typography>
                    <Typography variant="body2">
                      Total Sales: {product.totalSales}
                    </Typography>
                    <Typography variant="body2">
                      Revenue: ${product.revenue.toFixed(2)}
                    </Typography>
                  </Paper>
                </Grid>
              ))}
            </Grid>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}

export default Dashboard; 