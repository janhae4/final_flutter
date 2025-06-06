const express = require('express');
const app = express();
const cors = require('cors');
const AuthRoute = require('./routes/AuthRoute');
const EmailRoute = require('./routes/EmailRoute');
const { connectDb } = require('./db/db');
const http = require('http');
const { initSocket } = require('./db/websocket');
const path = require('path');

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use("/api/auth", AuthRoute)
app.use("/api/email", EmailRoute);

const startServer = async () => {
    const server = http.createServer(app);
    initSocket(server);
    await connectDb();
    server.listen(3000, () => console.log('Server is running on port 3000'));
};

startServer();