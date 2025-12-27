# iClaudius

A native macOS app for viewing, understanding, and managing your Claude Code configuration.

![iClaudius Icon](AppIcon.png)

## Features

- **Configuration Dashboard** - See all your Claude Code settings at a glance
- **Health Monitoring** - Green/yellow/red status alerts for configuration issues
- **CLAUDE.md Hierarchy** - View and edit all your CLAUDE.md files in order of precedence
- **Custom Slash Commands** - Browse, search, and edit your custom commands and aliases
- **Plugin Management** - See installed plugins and their enabled status
- **Cron Job CRUD** - Create, read, update, and delete scheduled automation tasks
- **Account Info** - View your Claude Code usage statistics
- **Smart Suggestions** - Get personalized recommendations to enhance your workflow

## Screenshots

### Overview Dashboard
The main dashboard shows your configuration health, hierarchy, account info, and quick stats.

### Custom Slash Commands
Browse all your custom commands with alias detection and inline editing.

### Cron Job Management
Full CRUD interface for managing scheduled tasks with preset templates.

## Requirements

- macOS 14.0 (Sonoma) or later
- Claude Code CLI installed (`claude --version`)

## Installation

### From Source
```bash
git clone https://github.com/yourusername/iClaudius.git
cd iClaudius
swift build -c release
cp -r .build/release/iClaudius.app /Applications/
```

### From Mac App Store
Coming soon!

## Usage

1. Launch iClaudius
2. The app automatically scans your `~/.claude` directory
3. Navigate using the sidebar:
   - **Overview** - Dashboard with health status and quick stats
   - **CLAUDE.md Files** - View/edit configuration files
   - **Custom Slash Commands** - Browse your commands
   - **Plugins** - See installed extensions
   - **Scheduled Jobs** - Manage cron automation
   - **Permissions** - View allowed commands
   - **Account Info** - Usage statistics

## Configuration Files Detected

- `~/.claude/CLAUDE.md` - Global instructions
- `~/CLAUDE.md` - User-level configuration
- Project-level CLAUDE.md files
- `~/.claude/commands/*.md` - Custom slash commands
- `~/.claude/skills/*.md` - Custom skills
- `~/.claude/settings.json` - Enabled plugins
- `~/.claude/settings.local.json` - Permission allowlists

## Privacy

iClaudius runs entirely locally on your Mac. It:
- Does NOT collect any data
- Does NOT make network requests
- Does NOT require an account
- Only reads your local Claude Code configuration files

See our [Privacy Policy](https://gist.github.com/fredzannarbor/60750621db34745c8df4d3e971292b7d) for details.

## License

MIT License - See [LICENSE](LICENSE) file.

## Credits

- Inspired by the BBC TV series and book "I, Claudius" by Robert Graves
- Built for the Claude Code community

## Contributing

Contributions welcome! Please open an issue or PR.
