#  VOLATILITY 2.6.1 - ONE-COMMAND INSTALLATION

## The Complete Solution

This is the **all-in-one** script you need. It does everything:

 Installs Python 2.7 and pip2  
 Installs all dependencies (distorm3, yara, pycrypto, etc.)  
 Clones Volatility 2.6.1 from GitHub  
 Fixes Python 2/3 compatibility issues  
 Creates wrapper scripts  
 Tests everything automatically  
 Shows you how to use it  

---

##  ONE COMMAND TO RULE THEM ALL

```bash
sudo bash install_volatility_complete.sh
```

**That's it!** Just run this one command and grab a coffee 

---

##  What This Script Does (Automatically)

### Phase 1: System Check
-  Checks you're running as root
-  Displays your current Python versions
-  Shows system information
-  Backs up any existing Volatility installation

### Phase 2: Python 2.7 Setup
-  Installs Python 2.7 and development packages
-  Installs pip2 (pip for Python 2.7)
-  Upgrades pip2 and setuptools
-  Installs all required dependencies:
  - distorm3
  - yara
  - pycrypto / pycryptodome
  - pillow
  - ujson
  - pytz
  - ipython
  - capstone

### Phase 3: Volatility Installation
-  Clones Volatility from official GitHub
-  Checks out version 2.6.1
-  Runs setup.py installation
-  Creates Yara library symlink

### Phase 4: Python Compatibility Fix
-  Updates vol.py shebang to use Python 2
-  Creates wrapper script that forces Python 2 execution
-  Creates multiple aliases (vol.py, vol2.py, volatility)
-  Adds bash aliases for convenience

### Phase 5: Testing
-  Tests direct Python 2 execution
-  Tests wrapper script
-  Verifies all critical plugins
-  Tests Yara integration
-  Tests Python package imports

### Phase 6: Completion
-  Shows you how to use Volatility
-  Displays example commands
-  Lists common Windows profiles
-  Shows version information

---

##  Quick Start After Installation

After the script completes, you can immediately use:

```bash
# Get help
vol.py -h

# Identify a memory image
vol.py -f memory.mem imageinfo

# List processes
vol.py -f memory.mem --profile=Win7SP1x64 pslist

# Find hidden processes
vol.py -f memory.mem --profile=Win7SP1x64 psxview

# Scan for malware
vol.py -f memory.mem --profile=Win7SP1x64 malfind
```

---

##  What Makes This Different?

### Compared to Basic Installation Scripts:
| Feature | Basic Script | This Script |
|---------|-------------|-------------|
| Installs Python 2 |  Assumes installed |  Auto-installs |
| Installs pip2 |  Assumes installed |  Auto-installs |
| Fixes Python 3 conflict |  No |  Yes |
| Creates wrapper |  Simple symlink |  Smart wrapper |
| Tests installation |  Minimal |  Comprehensive (5 tests) |
| User-friendly output |  Plain text |  Color-coded |
| Error handling |  Basic |  Advanced |
| Usage guide |  No |  Yes |

### Handles These Common Issues:
-  Python 3.13.5 as system default
-  Missing Python 2.7
-  Missing pip2
-  Yara library linking issues
-  Python 2/3 syntax conflicts
-  Existing installations (backs them up)

---

##  System Requirements

- **OS**: Kali Linux (or Debian-based)
- **Privileges**: Root/sudo access
- **Internet**: Required for downloads
- **Disk Space**: ~500 MB

---

##  What You'll See

The script uses color-coded output:

-  **[INFO]** - Information messages
-  **[SUCCESS]** - Successful operations
-  **[WARNING]** - Non-critical warnings
-  **[ERROR]** - Critical errors
-  **[STEP]** - Current step being executed
-  **Headers** - Major sections

---

##  Installation Time

**Typical installation time**: 5-10 minutes

Depends on:
- Your internet speed (downloading packages)
- Your system speed (compiling packages)
- Whether Python 2 is already installed

---

##  Troubleshooting

### Script fails to start?
```bash
# Ensure you have sudo
sudo bash install_volatility_complete.sh

# Check you downloaded it correctly
ls -lh install_volatility_complete.sh
```

### Installation fails midway?
```bash
# Check the logs
cat /tmp/volatility_install.log
cat /tmp/volatility_deps.log

# Try running again - it backs up existing installations
sudo bash install_volatility_complete.sh
```

### Want to see what Python 2 version you have?
```bash
python2 --version
```

### Need to uninstall?
```bash
# Remove Volatility
sudo rm -rf ~/volatility
sudo rm -rf /root/volatility

# Remove wrapper scripts
sudo rm /usr/local/bin/vol.py
sudo rm /usr/local/bin/vol2.py
sudo rm /usr/local/bin/volatility

# Remove Python 2 (optional)
sudo apt-get remove python2
```

---

##  After Installation

### Test it works:
```bash
vol.py -h
```

### Find your Volatility location:
```bash
which vol.py
ls -la ~/volatility/
```

### Check logs:
```bash
cat /tmp/volatility_install.log
cat /tmp/vol_test_wrapper.txt
```

### See all available plugins:
```bash
vol.py -h | grep -A 100 "Supported Plugin"
```

### List all profiles:
```bash
vol.py --info | grep Profile
```

---

##  Workshop Ready

This script follows the instructions from your workshop document but **automates everything** and **fixes the Python issues** that students commonly encounter.

Perfect for:
- INF4019W Digital Forensics Workshop
- Memory forensics courses
- CTF competitions
- Incident response training
- Malware analysis labs

---

##  Technical Details

**What the wrapper script does:**
```bash
#!/bin/bash
# Finds your vol.py location
# Executes it with: python2 vol.py [your arguments]
```

This ensures that even though your system defaults to Python 3.13.5, Volatility always runs with Python 2.7.

**Python version isolation:**
- System default: Python 3.13.5 (unchanged)
- Volatility: Python 2.7 (isolated)
- No conflicts between the two

---

##  Why This Script Exists

Your workshop instructions are great, but they:
1. Assume Python 2 is already set up 
2. Don't handle Python 3 as system default 
3. Require manual typing of many commands 
4. Can fail if steps are done out of order 

This script:
1. Installs everything you need 
2. Handles Python 3 conflicts automatically 
3. Runs with one command 
4. Can't be done out of order (it's automated) 

---

##  Pro Tips

1. **Save the script**: Keep it for future installations
2. **Run on fresh Kali**: Works on brand new Kali installations
3. **Multiple machines**: Use it on all your VMs
4. **Share with classmates**: Help everyone get set up fast

---

##  Ready to Install?

### Get it from GitHub (Kali)

```bash
# Clone the repo
git clone git@github.com:cloudenochcsis/Volatility-Script.git

# Enter the folder
cd Volatility-Script

# Make the script executable
chmod +x install_volatility_complete.sh
```

### Run the installer

```bash
sudo bash install_volatility_complete.sh
```

Sit back and watch it work! The script will:
- Show you what it's doing at each step
- Back up any existing installation
- Install everything needed
- Fix all compatibility issues
- Test everything
- Show you how to use it

**Total time: ~5-10 minutes** 

---

##  Success Indicators

You'll know it worked when you see:

```
========================================
INSTALLATION COMPLETE!
========================================

 Volatility 2.6.1 is installed and ready to use

You can now run Volatility using any of these commands:

  vol.py -h              # Primary command (recommended)
  vol2.py -h             # Alternative name
  volatility -h          # Alternative name
```

Then just run: `vol.py -h` and you're good to go! 

---

**Created for**: Digital Forensics Workshop  
**Tested on**: Kali Linux with Python 3.13.5  
**Script version**: 1.0 (Comprehensive Edition)
