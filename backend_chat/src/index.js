// src/index.js
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// Use express.json() middleware to parse JSON bodies
app.use(express.json());

io.on('connection', (socket) => {
    console.log('User connected');

    // Handle chat events
    socket.on('chat message', (msg) => {
        console.log(`User sent a message: ${msg}`);
        io.emit('chat message', msg);
    });

    // Handle disconnect event
    socket.on('disconnect', () => {
        console.log('User disconnected');
    });
});

// Handle POST requests to the root endpoint
app.post('/', (req, res) => {
    const { message } = req.body;

    if (message) {
        // If the request contains a 'message' parameter, emit it using Socket.IO
        io.emit('chat message', message);
        res.send(`Received a POST request with message: ${message}`);
    } else {
        // If 'message' parameter is missing, return an error response
        res.status(400).send('Bad Request: Missing "message" parameter');
    }
});

// Add a simple status endpoint
app.get('/status', (req, res) => {
    res.send('Server is running');
});

const port = process.env.PORT || 3000;
server.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});
