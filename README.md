# Running Roulette

**Running Roulette** is a Garmin watch app that gamifies your running routine by spinning a roulette wheel to randomly select your next running distance. Perfect for runners who want to add spontaneity and fun to their training!

## Screenshots

![Roulette App Screenshot](screenshots/image.png)

## Features

- **Interactive Roulette Wheel**: Animated spinning wheel with visual feedback and smooth transitions
- **Multiple Distance Profiles**: Choose from four pre-configured distance ranges:
  - **5K Profile**: Random distances from 0.5K to 5K (10 segments)
  - **10K Profile**: Random distances from 1K to 10K (16 segments)
  - **Half Marathon Profile**: Random distances from 1K to 21K (16 segments)
  - **Marathon Profile**: Random distances from 1K to 42K (16 segments)
- **Multi-Language Support**: Available in English, Spanish, and Portuguese
- **Visual Design**: Casino-style roulette with alternating red/black segments and gold accents

## How It Works

1. **Launch the App**: Open Running Roulette on your Garmin watch
2. **Select Distance Profile** (Optional): Press the menu button and choose "Distances" to select your preferred distance range (5K, 10K, Half Marathon, or Marathon)
3. **Spin the Wheel**: Press the menu button and select "Spin" to start the roulette animation
4. **Get Your Distance**: Watch the wheel spin and land on a random distance
5. **Go Run!**: The selected distance is displayed in the center with a "GO RUN!" prompt

## Compatibility

This app is compatible with a wide range of Garmin devices, including:

- **Forerunner Series**: 165, 165M, 255, 255M, 255S, 255SM, 265, 265S, 570 (42mm/47mm), 955, 965, 970
- **Fenix Series**: 7, 7S, 7X, 7 Pro, 8 (43mm/47mm), 8 Pro, 8 Solar, Fenix E
- **Epix Series**: Epix 2, Epix 2 Pro (42mm/47mm/51mm)

Tested primarily on **Garmin Forerunner 965**.

## Development Setup

### Prerequisites

1. **Garmin Connect IQ SDK**:
   - Download and install the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) from Garmin's developer portal
   - Set up your development environment following Garmin's official documentation

2. **IDE Options**:
   - **Visual Studio Code** with the Monkey C extension (recommended)
   - **Eclipse** with the Connect IQ plugin

### Building the App

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd roulette
   ```

2. **Build the project**:
   - Using VS Code: Open the project and use the Monkey C build commands
   - Using command line: Use the MonkeyC compiler with the appropriate device target

3. **Deploy to device**:
   - Connect your Garmin device via USB
   - Use the Connect IQ SDK tools to deploy the compiled `.prg` file to your device

### Project Structure

```
roulette/
├── source/                          # MonkeyC source files
│   ├── RouletteRunnerApp.mc        # Main application entry point
│   ├── RouletteRunnerAppView.mc    # View rendering and animation logic
│   ├── RouletteRunnerMenuDelegate.mc
│   ├── RouletteRunnerMenuBehavior.mc
│   └── RouletteRunnerMenuDistancesDelegate.mc
├── resources/                       # App resources
│   ├── drawables/                  # Icons and images
│   ├── jsonData/                   # Distance profile data
│   ├── layouts/                    # UI layouts
│   ├── menus/                      # Menu definitions
│   └── strings/                    # English strings
├── resources-spa/                   # Spanish translations
├── resources-por/                   # Portuguese translations
├── manifest.xml                     # App manifest and device compatibility
└── monkey.jungle                    # Build configuration
```

## Customization

### Adding Custom Distance Profiles

Distance profiles are defined in `resources/jsonData/resources.xml`. Each profile is a JSON array of distance strings:

```xml
<jsonData id="customProfile">["1K", "2K", "3K", "5K", "8K", "13K"]</jsonData>
```

To add a new profile:
1. Add your JSON data to `resources/jsonData/resources.xml`
2. Update the menu in `resources/menus/roulette_runner_distances_menu.xml`
3. Add corresponding string resources for the profile name
4. Update the menu delegate to handle the new profile selection

### Modifying Colors

The roulette wheel colors are defined in `RouletteRunnerAppView.mc`:
- Red segments: `0xCC0000`
- Black segments: `0x1A1A1A`
- Gold accents: `0x888800`
- Selected segment: `0x444400`

### Adding Languages

To add a new language:
1. Create a new `resources-{lang}/` directory (e.g., `resources-fra/` for French)
2. Copy `strings.xml` from `resources/strings/` and translate all strings
3. Add the language code to `manifest.xml` under `<iq:languages>`

## Technical Details

- **Language**: MonkeyC (Garmin's proprietary language)
- **Min API Level**: 3.2.0
- **App Type**: Watch App
- **Animation**: Custom wheel rotation with physics-based deceleration
- **Rendering**: Canvas-based drawing with polygon fills for segments

## Roadmap

- [ ] Add customizable distance values (time-based, rep-based workouts)
- [ ] Support for additional Garmin device families (Venu, Enduro)
- [ ] Display workout suggestions based on training objectives
- [ ] Save spin history and statistics
- [ ] Integration with Garmin training plans

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or feature requests, please open an issue on the GitHub repository.
