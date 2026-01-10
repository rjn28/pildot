# MacOS Battery Bar App

A lightweight macOS status bar application written in Swift. It replaces the standard system battery icon with a compact version that displays the battery percentage *inside* the icon, saving valuable horizontal screen space on notched MacBooks.

## Features
- **Compact Design:** Integrates percentage text inside the battery icon.
- **Native Look:** Uses CoreGraphics to draw a battery icon that matches the system aesthetic.
- **Lightweight:** Minimal resource usage.
- **Dark/Light Mode Support:** Automatically adapts to system appearance.

## Installation / Build

1.  Clone the repository.
2.  Compile the app using Swift:
    ```bash
    swiftc main.swift -o BatteryIconApp
    ```
3.  Run the app:
    ```bash
    ./BatteryIconApp
    ```

## Auto-Start
To make the app start at login:
1.  Go to **System Settings** -> **General** -> **Login Items**.
2.  Add the `BatteryIconApp` executable to the list.

## License
MIT
