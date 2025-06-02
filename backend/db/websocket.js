// socket.js
const { Server } = require('socket.io');
const EventEmitter = require('events');
const jwt = require('jsonwebtoken');
const loginEvents = new EventEmitter();
const userSockets = new Map();
const pendingLogins = {};
require('dotenv').config();

const initSocket = (server) => {
    const io = new Server(server, {
        cors: {
            origin: "*",
            methods: ["GET", "POST"]
        }
    });

    io.use((socket, next) => {
        const token = socket.handshake.auth.token;

        if (!token) {
            return next(new Error('Authentication error'));
        }
        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            socket.userId = decoded.id;
            next();
        } catch (err) {
            next(new Error('Authentication error'));
        }
    });

    io.on("connection", (socket) => {
        console.log("Socket connected", socket.id);

        const userId = socket.userId;
        userSockets.set(userId, socket);
        console.log(`User ${userId} connected`);

        socket.on("disconnect", () => {
            console.log(`User ${userId} disconnected`);
            userSockets.delete(userId);
        });
    });
}

module.exports = { initSocket, userSockets };
