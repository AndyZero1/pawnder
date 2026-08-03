const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client')
require('dotenv').config();

const app = express();
const prisma = new PrismaClient();

app.use(express.json());

// POST /api/auth/register
app.post('/api/auth/register', async (req, res) => {
    try {
        const { username, email, password, rol, cabinet_name } = req.body;

        
    }
})