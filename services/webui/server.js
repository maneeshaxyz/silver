const express = require('express');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 3001;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Serve the main HTML page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API endpoint for initial setup (init.sh)
app.post('/api/setup-silver-mail', async (req, res) => {
    try {
        const { domain, username, password, firstName, lastName, age, phone } = req.body;
        
        // Validate required fields
        if (!domain || !username || !password || !firstName || !lastName) {
            return res.status(400).json({ error: 'Missing required fields' });
        }
        
        console.log('Starting Silver Mail setup for domain:', domain);
        
        // Execute init.sh with inputs
        const initProcess = spawn('bash', ['../init.sh'], {
            cwd: __dirname,
            stdio: ['pipe', 'pipe', 'pipe']
        });
        
        // Prepare inputs for the script
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
        
        // Send inputs to the script
        initProcess.stdin.write(inputs);
        initProcess.stdin.end();
        
        initProcess.on('close', (code) => {
            if (code === 0) {
                res.json({
                    success: true,
                    message: 'Silver Mail setup completed successfully!',
                    output: output
                });
            } else {
                res.status(500).json({
                    error: 'Setup script failed',
                    code: code,
                    output: output,
                    errorOutput: errorOutput
                });
            }
        });
        
        // Handle timeout (30 minutes)
        setTimeout(() => {
            if (!initProcess.killed) {
                initProcess.kill();
                res.status(408).json({ error: 'Setup timeout - process took too long' });
            }
        }, 30 * 60 * 1000);
        
    } catch (error) {
        console.error('Server error:', error);
        res.status(500).json({ error: 'Internal server error: ' + error.message });
    }
});

// API endpoint for adding users (add_user.sh)
app.post('/api/add-user', async (req, res) => {
    try {
        const { username, password, firstName, lastName, age, phone } = req.body;
        
        // Validate required fields
        if (!username || !password || !firstName || !lastName) {
            return res.status(400).json({ error: 'Missing required fields' });
        }
        
        console.log('Adding new user:', username);
        
        // Execute add_user.sh with inputs
        const addUserProcess = spawn('bash', ['../add_user.sh'], {
            cwd: __dirname,
            stdio: ['pipe', 'pipe', 'pipe']
        });
        
        // Prepare inputs for the script
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
        
        // Send inputs to the script
        addUserProcess.stdin.write(inputs);
        addUserProcess.stdin.end();
        
        addUserProcess.on('close', (code) => {
            if (code === 0) {
                res.json({
                    success: true,
                    message: 'User added successfully!',
                    output: output
                });
            } else {
                res.status(500).json({
                    error: 'Add user script failed',
                    code: code,
                    output: output,
                    errorOutput: errorOutput
                });
            }
        });
        
        // Handle timeout (10 minutes)
        setTimeout(() => {
            if (!addUserProcess.killed) {
                addUserProcess.kill();
                res.status(408).json({ error: 'Add user timeout - process took too long' });
            }
        }, 10 * 60 * 1000);
        
    } catch (error) {
        console.error('Server error:', error);
        res.status(500).json({ error: 'Internal server error: ' + error.message });
    }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Check system status
app.get('/api/status', (req, res) => {
    try {
        // Check if .env files exist
        const localEnvExists = fs.existsSync('../.env');
        const thunderEnvExists = fs.existsSync('../thunder/scripts/.env');
        
        res.json({
            initialized: localEnvExists && thunderEnvExists,
            localEnv: localEnvExists,
            thunderEnv: thunderEnvExists
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Start server
app.listen(PORT, () => {
    console.log(`Silver Mail Web UI running on http://localhost:${PORT}`);
    console.log('Make sure you are running this from the services/webui directory');
});

module.exports = app;