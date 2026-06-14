const express = require('express');
const path = require('path');

const app = express();

app.use(express.static(path.join(__dirname, 'public')));

app.get('/config', (req, res) => {
    res.json({
        backendUrl: process.env.BACKEND_URL || 'http://localhost:3001'
    });
});

app.get('/health', (req, res) => {
    res.status(200).send('Frontend is healthy');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Frontend server running on port ${PORT}`);
});