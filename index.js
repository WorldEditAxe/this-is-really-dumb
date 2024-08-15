const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const pty = require('node-pty');
const cors = require('cors');
const { exec } = require('child_process');
const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');

const RESTART_INTERVAL = 6 * 60 * 60 * 1000;
setTimeout(() => process.exit(-1), RESTART_INTERVAL);

const app = express();
const server = http.createServer(app);
const io = socketIo(server, { cors: {} });
const startTime = Date.now();

app.use(cors());

// Constants for limitations
const MAX_RAM_PER_USER = 256 * 1024; // 256MB in KB
const MAX_STORAGE_PER_USER = 5 * 1024 * 1024; // 5GB in KB
const MAX_PROCESSES_PER_USER = 10;

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

    // Copy INFO.txt to the new user's directory
    await fs.copyFile(path.join(__dirname, 'INFO.txt'), `${userHome}/INFO.txt`);

    const uploadShContent = await fs.readFile(path.join(__dirname, 'upload.sh'), 'utf8');
    await fs.appendFile(`${userHome}/.bashrc`, `\n\n# Contents of upload.sh\n${uploadShContent}`);

    const startShell = () => {
      const shell = 'bash';
      exec(`ulimit -v ${MAX_RAM_PER_USER} && ulimit -f ${MAX_STORAGE_PER_USER} && ulimit -n ${MAX_PROCESSES_PER_USER}`, (error, stdout, stderr) => {
        if (error) {
          console.error(`Error setting ulimit: ${error}`);
          return;
        }
      });

      // Spawn the terminal as the specified user
      const term = pty.spawn('su', ['-', username, '-c', `script -qc "${shell}" /dev/null`], {
        name: 'xterm-color',
        cols: 80,
        rows: 30,
        cwd: userHome,
        env: { ...process.env, HOME: userHome, TERM: 'xterm-color' }
      });
      
      term.on('data', (data) => {
        socket.emit('output', data);
      });

      // Only restart the shell when it exits normally (not due to client disconnect)
      term.on('exit', (code) => {
        if (code === 0) {
          startShell();
        }
      });

      socket.on('input', (data) => {
        term.write(data);
      });

      // Fix terminal resizing by using the correct event name
      socket.on('resize', (size) => {
        term.resize(size.cols, size.rows);
        term.emit('resize', size);
      });

      return term;
    };

    let currentTerm = startShell();

    socket.on('disconnect', () => {
      currentTerm.kill();
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
