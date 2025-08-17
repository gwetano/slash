# slash

slash is a minimal desktop app built with Electron that provides a floating search bar for quick commands, web searches, calculations, and more.

## Features

- **Always-on-top** floating search bar
- **Automatic window resizing** based on input length
- **Quick commands** with `/command argument` syntax
- **Math operations** directly in the bar (`2+2`, `5^3`, etc.)
- **Auto-updates** from GitHub releases
- **Local file search** integration
- **Command history** with arrow keys
- **Tab completion** for commands

## Built-in Commands

| Command | Action | Example |
|---------|--------|---------|
| `/google <query>` | Search on Google | `/google electron tutorial` |
| `/wiki <query>` | Search on Wikipedia | `/wiki javascript` |
| `/yt <query>` | Search on YouTube | `/yt music playlist` |
| `/duck <query>` | Search on DuckDuckGo | `/duck privacy tools` |
| `/open <url>` | Open website | `/open github. com` |
| `/file <query>` | Search local files | `/file readme` |
| `/update` | Check for app updates | `/update` |
| `exit` | Close the app | `exit` |

## Installation

### macOS

```bash
bash mac-install.sh
```

### Linux

```bash
bash lin-install.sh
```

### Windows

```batch
win-install.bat
```

*(Right-click → "Run as administrator" for system-wide installation)*

## 🔒 Security Considerations

This app is not yet code-signed, so you may see security warnings:

### macOS Users

- Right-click the app →"Open" instead of double-clicking
- Or go to `System Preferences → Security & Privacy → Allow anyway`

### Windows Users

- If you see"Windows protected your PC":
  1. Click"More info"
  2. Click"Run anyway"

### Why these warnings appear

Code signing certificates cost ~$300/year. The app is completely safe - you can review all source code in this repository.

## Usage

1. **Launch** the app (it appears as a small search bar)
2. **Type** a command or math expression
3. **Press Enter** to execute
4. **Use arrow keys** to navigate command history
5. **Press Tab** for command auto-completion
6. **Type** `exit` to quit

### Quick Examples

- `2+2` → Fast calculator
- `/google electron` → Google search
- `/file project` → Find local files
- `/open reddit. com` → Open website
- `/update` → Check for updates

## Auto-Updates

*slash* automatically checks for updates:
- ✅ On app startup
- ✅ Manual check with `/update` command

When an update is available:
1. Downloads automatically in background
2. Notifies you when ready
3. You choose when to restart and apply
***

## Development

### Prerequisites

- Node. js (v16 or later)
- npm

### Setup

```bash
git clone https://github.com/gwetano/slash.git
cd slash
npm install
```

### Run

```bash
npm start
```

### Build

```bash
# Build for current platform
npm run dist
```

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Adding New Commands

Edit `renderer. js` and add to the `commands` object:

```javascript
const commands = {
  // Existing commands...
  
  mycommand(args) {
    // Your command logic here
    console.log('Args:', args);
  }
};

// Add to commandsList for tab completion
const commandsList = ['google', 'wiki', 'yt', 'duck', 'open', 'file', 'update', 'mycommand'];
```

## License

MIT License - see [LICENSE](LICENSE) file for details.
***

## Issues & Support

- **Bug reports**:  [GitHub Issues](https://github.com/gwetano/slash/issues)

- **Feature requests**: [GitHub Discussions](https://github.com/gwetano/slash/discussions)
