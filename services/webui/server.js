const express = require('express');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const https = require('https');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const app = express();

// =====================
// Load env values
// =====================
const MAIL_DOMAIN = process.env.MAIL_DOMAIN || 'localhost';
const HTTP_PORT = process.env.HTTP_PORT || 80;   // HTTP for redirect
const HTTPS_PORT = process.env.HTTPS_PORT || 443; // HTTPS secure port

// =====================
// Middleware
// =====================
app.use(express.json());
app.use(express.static('public'));

// Serve main HTML page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// =====================
// API: init.sh
// =====================
app.post('/api/setup-silver-mail', async (req, res) => {
    try {
        const { domain, username, password, firstName, lastName, age, phone } = req.body;

        if (!domain || !username || !password || !firstName || !lastName) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        console.log('Starting Silver Mail setup for domain:', domain);

        const initProcess = spawn('bash', ['../init.sh'], {
            cwd: __dirname,
            stdio: ['pipe', 'pipe', 'pipe']
        });

        const inputs = `${domain}\n${username}\n${password}\n${firstName}\n${lastName}\n${age || ''}\n${phone || ''}\n`;

        let output = '';
        let errorOutput = '';

        initProcess.stdout.on('data', (data) => {
            output += data.toString();
            console.log('INIT STDOUT:', data.toString());
        });

        initProcess.stderr.on('data', (data) => {
            errorOutput += data.toString();
            console.error('INIT STDERR:', data.toString());
        });

        initProcess.stdin.write(inputs);
        initProcess.stdin.end();

        initProcess.on('close', (code) => {
            if (code === 0) {
                res.json({ success: true, message: 'Setup completed successfully!', output });
            } else {
                res.status(500).json({ error: 'Setup failed', code, output, errorOutput });
            }
        });

        setTimeout(() => {
            if (!initProcess.killed) {
                initProcess.kill();
                res.status(408).json({ error: 'Setup timeout' });
            }
        }, 30 * 60 * 1000);

    } catch (error) {
        console.error('Server error:', error);
        res.status(500).json({ error: error.message });
    }
});

// =====================
// API: add_user.sh
// =====================
app.post('/api/add-user', async (req, res) => {
    try {
        const { username, password, firstName, lastName, age, phone } = req.body;

        if (!username || !password || !firstName || !lastName) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        console.log('Adding user:', username);

        const addUserProcess = spawn('bash', ['../add_user.sh'], {
            cwd: __dirname,
            stdio: ['pipe', 'pipe', 'pipe']
        });

        const inputs = `${username}\n${password}\n${firstName}\n${lastName}\n${age || ''}\n${phone || ''}\n`;

        let output = '';
        let errorOutput = '';

        addUserProcess.stdout.on('data', (data) => {
            output += data.toString();
            console.log('ADD_USER STDOUT:', data.toString());
        });

        addUserProcess.stderr.on('data', (data) => {
            errorOutput += data.toString();
            console.error('ADD_USER STDERR:', data.toString());
        });

        addUserProcess.stdin.write(inputs);
        addUserProcess.stdin.end();

        addUserProcess.on('close', (code) => {
            if (code === 0) {
                res.json({ success: true, message: 'User added successfully!', output });
            } else {
                res.status(500).json({ error: 'Add user failed', code, output, errorOutput });
            }
        });

        setTimeout(() => {
            if (!addUserProcess.killed) {
                addUserProcess.kill();
                res.status(408).json({ error: 'Add user timeout' });
            }
        }, 10 * 60 * 1000);

    } catch (error) {
        console.error('Server error:', error);
        res.status(500).json({ error: error.message });
    }
});

// =====================
// Health & Status
// =====================
app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.get('/api/status', (req, res) => {
    try {
        const localEnv = fs.existsSync('../.env');
        const thunderEnv = fs.existsSync('../thunder/scripts/.env');
        res.json({ initialized: localEnv && thunderEnv, localEnv, thunderEnv });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// =====================
// HTTPS Setup
// =====================
const SSL_CERT_PATH = path.join(__dirname, `../letsencrypt/live/${MAIL_DOMAIN}/fullchain.pem`);
const SSL_KEY_PATH = path.join(__dirname, `../letsencrypt/live/${MAIL_DOMAIN}/privkey.pem`);

if (fs.existsSync(SSL_CERT_PATH) && fs.existsSync(SSL_KEY_PATH)) {
    // HTTPS server
    https.createServer(
        { key: fs.readFileSync(SSL_KEY_PATH), cert: fs.readFileSync(SSL_CERT_PATH) },
        app
    ).listen(HTTPS_PORT, () => {
        console.log(`✅ HTTPS running at https://${MAIL_DOMAIN}`);
    });

    // HTTP server (redirect to HTTPS)
    const redirectApp = express();
    redirectApp.use((req, res) => {
        res.redirect(`https://${MAIL_DOMAIN}${req.url}`);
    });
    redirectApp.listen(HTTP_PORT, () => {
        console.log(`🌐 HTTP redirecting to HTTPS on port ${HTTP_PORT}`);
    });

} else {
    console.warn('⚠️ SSL certs not found. Starting HTTP only.');
    app.listen(HTTP_PORT, () => {
        console.log(`HTTP running at http://localhost:${HTTP_PORT}`);
    });
}

module.exports = app;