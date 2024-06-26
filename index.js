const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const pty = require('node-pty');

const RESTART_IN = 6 * 60 * 60 * 1000

setTimeout(() => process.exit(-1), RESTART_IN)

const app = express();
const server = http.createServer(app);
const io = socketIo(server);
const startTime = Date.now();

// Serve static files from the 'public' directory
app.use(express.static('public'));

// Set up a route to the terminal
app.get('/terminal', (req, res) => {
  res.sendFile(__dirname + '/public/terminal.html');
});

function formatTime(milliseconds) {
  let seconds = Math.floor(milliseconds / 1000);
  let hours = Math.floor(seconds / 3600);
  let minutes = Math.floor((seconds % 3600) / 60);
  seconds = seconds % 60;

  return `${hours}h ${minutes}m ${seconds}s`;
}

app.get('/uptime', (req, res) => {
  res.writeHead(200).end(JSON.stringify({
    uptime: formatTime(Date.now() - startTime),
    timeTillRestart: formatTime((startTime + RESTART_IN) - Date.now())
  }))
})

// Start the server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

// Handle socket connections
io.of('term').on('connection', (socket) => {
  console.log('A user connected');

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
    console.log('User disconnected');
    term.destroy();
  });
});
