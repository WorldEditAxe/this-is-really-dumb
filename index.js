const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const pty = require('node-pty');
const cors = require('cors');
const { exec } = require('child_process');
const crypto = require('crypto')
const fs = require('fs').promises;
const path = require('path');

const RESTART_INTERVAL = 6 * 60 * 60 * 1000;
setTimeout(() => process.exit(-1), RESTART_INTERVAL);

const app = express();
const server = http.createServer(app);
const io = socketIo(server, { cors: {} });
const startTime = Date.now();

app.use(cors());

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

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

io.of('/uptime').on('connection', socket => {
  socket.emit("result", JSON.stringify({
    uptime: formatTime(Date.now() - startTime),
    timeTillRestart: formatTime(startTime + RESTART_INTERVAL - Date.now())
  }));
  socket.disconnect(0);
});

io.of('/term').on('connection', async (socket) => {
  const username = `user_${crypto.randomUUID().split('-')[0]}`;
  const userHome = `/home/${username}`;
  
  try {
    await new Promise((resolve, reject) => {
      exec(`useradd -m ${username}`, (error) => {
        if (error) reject(error);
        else resolve();
      });
    });

    // Read the contents of upload.sh
    const uploadShContent = await fs.readFile(path.join(__dirname, 'upload.sh'), 'utf8');

    // Append the contents of upload.sh to the user's .bashrc
    await fs.appendFile(`${userHome}/.bashrc`, `\n\n# Contents of upload.sh\n${uploadShContent}`);

    const shell = 'bash';
    const term = pty.spawn(shell, [], {
      name: 'xterm-color',
      cols: 80,
      rows: 30,
      cwd: userHome,
      env: { ...process.env, HOME: userHome }
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
      exec(`userdel -r ${username}`, (error) => {
        if (error) {
          console.error(`Error deleting user: ${error}`);
        }
      });
    });

  } catch (error) {
    console.error(`Error setting up user: ${error}`);
    socket.disconnect();
  }
});
