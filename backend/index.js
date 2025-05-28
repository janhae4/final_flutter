const express = require('express');
const app = express();
const cors = require('cors');
const AuthRoute = require('./routes/AuthRoute');
const { connectDb } = require('./db/db');

app.use(cors());
app.use(express.json());

app.use("/api/auth", AuthRoute)

const startServer = async () => {
    await connectDb();
    app.listen(3000, () => console.log('Server is running on port 3000'));
};

startServer();