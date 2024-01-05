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
    console.log(`User connected: ${socket.id}`);

    // Handle setting and broadcasting usernames
    socket.on('set username', (username) => {
        socket.username = username;
        // Broadcast a message that a new user has joined the chat
        io.emit('chat message', { username: 'Server', message: `${username} has joined the chat` });
        console.log(`User ${socket.id} set username to: ${username}`);
    });

    // Handle chat events
    socket.on('chat message', (msg) => {
        // Broadcast the received message to all connected clients, including the sender's username
        io.emit('chat message', { username: socket.username, message: msg });
        console.log(`User ${socket.id} sent a message: ${msg}`);
    });

    // Handle disconnect event
    socket.on('disconnect', () => {
        if (socket.username) {
            // Broadcast a message that the user has left the chat
            io.emit('chat message', { username: 'Server', message: `${socket.username} has left the chat` });
            console.log(`User ${socket.id} disconnected (${socket.username})`);
        } else {
            console.log(`User ${socket.id} disconnected`);
        }
    });
});

// Add a simple status endpoint
app.get('/status', (req, res) => {
    res.send('Server is running');
});

const port = process.env.PORT || 9000;
server.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});
