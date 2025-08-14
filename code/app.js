const express = require('express');
const mysql = require('mysql2/promise');
const path = require('path');
require('dotenv').config();

const app = express();

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});


// Setup EJS templating engine
app.set('views', path.join(__dirname, 'templates'));
app.set('view engine', 'ejs');

// Serve static files
app.use('/static', express.static(path.join(__dirname, 'static')));

app.get('/', async (req, res) => {
  try {
    const connection = await mysql.createConnection({
      host: process.env.DATABASE_HOST,
      user: process.env.DATABASE_USER,
      password: process.env.DATABASE_PASSWORD,
      database: process.env.DATABASE_NAME || 'company',
      port: process.env.DATABASE_PORT || 3306
    });

    const [rows] = await connection.execute(`SELECT * FROM ${process.env.DATABASE_TABLE || 'employees'}`);
    await connection.end();

    res.render('index', {
      students: rows,
      hostname: process.env.HOSTNAME || 'Unknown Host',
      version: '1.0.0'
    });

  } catch (err) {
    console.error('Database error:', err);
    res.status(500).send('<h3>Database Connection Error</h3><p>Please try again later.</p>');
  }
});

// Start server
const PORT = process.env.FLASK_PORT || 8080;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`App running on port ${PORT}`);
});

