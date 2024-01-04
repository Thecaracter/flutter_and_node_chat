// src/index.js
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

io.on('connection', (socket) => {
    console.log('User connected');

    // Handle chat events
    socket.on('chat message', (msg) => {
        io.emit('chat message', msg);
    });

    // Handle disconnect event
    socket.on('disconnect', () => {
        console.log('User disconnected');
    });
});

// Add a simple status endpoint
app.get('/status', (req, res) => {
    res.send('Server is running');
});

const port = process.env.PORT || 3000;
server.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});
