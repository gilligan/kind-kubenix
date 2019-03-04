#!/usr/bin/env node

const express = require('express');
const app = express();
const port = process.env.APP_PORT ? process.env.APP_PORT : 3000;


app.get('/', (req, res) => res.send('Hello World'));
app.listen(port, () => console.log(`Listening on port ${port}`));
