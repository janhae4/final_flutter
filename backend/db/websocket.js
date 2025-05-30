// socket.js
const { Server } = require('socket.io');
const EventEmitter = require('events');
const loginEvents = new EventEmitter();
const userSockets = new Map();
const pendingLogins = {};

const initSocket = (server) => {
    const io = new Server(server, {
        cors: {
            origin: "*",
            methods: ["GET", "POST"]
        }
    });

    io.on("connection", (socket) => {
        console.log("Socket connected");
        const userId = socket.handshake.query.userId;
        if (!userId) return;

        console.log(`User ${userId} connected`);
        userSockets.set(userId, socket);

        socket.on("disconnect", () => {
            console.log(`User ${userId} disconnected`);
            userSockets.delete(userId);
        });

        socket.on("login_response", ({ sessionId, approved }) => {
            if (pendingLogins[sessionId]) {
                pendingLogins[sessionId].resolve(approved);
                delete pendingLogins[sessionId];
            }
        });
    });
}

const sendLoginRequest = (userId, sessionId) => {
    const socket = userSockets.get(userId);
    if (socket) {
        socket.emit("login_request", { sessionId, timestamp: Date.now() });
    }
};

const waitForUserDecision = (sessionId) => {
    return new Promise((resolve) => {
        const timeout = setTimeout(() => {
            loginEvents.removeAllListeners(sessionId);
            resolve(false);
        }, 6000);

        loginEvents.on(sessionId, (approved) => {
            clearTimeout(timeout);
            loginEvents.removeAllListeners(sessionId);
            resolve(approved);
        });
    });
};

const onUserDecision = (sessionId, approved) => {
    loginEvents.emit(sessionId, approved);
};

module.exports = { initSocket, sendLoginRequest, waitForUserDecision, onUserDecision };
