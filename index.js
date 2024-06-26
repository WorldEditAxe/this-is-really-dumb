const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const pty = require('node-pty');
const fs = require("fs")

// we want our host to create a new container
let excepted = false
try { fs.readFileSync(".shouldquit") }
catch (err) { excepted = true }
if (!excepted) process.exit(-1)

// const RESTART_INTERVAL = 6 * 60 * 60 * 1000;
const RESTART_INTERVAL = 60 * 1000

setTimeout(() => process.exit(-1), RESTART_INTERVAL);

const app = express();
const server = http.createServer(app);
const io = socketIo(server);
const startTime = Date.now();

const termPage = fs.readFileSync("public/index.html")

function formatTime(milliseconds) {
  let seconds = Math.floor(milliseconds / 1000);
  let hours = Math.floor(seconds / 3600);
  let minutes = Math.floor((seconds % 3600) / 60);
  seconds = seconds % 60;

  return `${hours}h ${minutes}m ${seconds}s`;
}

app.get('/uptime', (req, res) => {
  res.json({
    uptime: formatTime(Date.now() - startTime),
    timeTillRestart: formatTime(startTime + RESTART_INTERVAL - Date.now())
  });
});

app.get('/', (req, res) => {
  res.header("Content-Type", "text/html").writeHead(200).end(termPage)
})

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

io.of('/term').on('connection', (socket) => {
  const shell = process.platform === 'win32' ? 'powershell.exe' : 'bash';

  const term = pty.spawn(shell, [], {
    name: 'xterm-color',
    cols: 80,
    rows: 30,
    cwd: process.env.HOME,
    env: process.env
  });

  term.on('data', (data) => {
    socket.emit('output', data);
  });

  socket.on('input', (data) => {
    term.write(data);
  });

  socket.on('resize', (size) => {
    term.resize(size.cols, size.rows);
  });

  socket.on('disconnect', () => {
    term.destroy();
  });
});
