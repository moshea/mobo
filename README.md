Manage your android devices easily with one yaml file.

Define, boot up and tear down all with simple commands
Performs system checks before booting each emulator and installs any android libraries that are needed to boot the emulator, including base android, android tools and android platform tools.

Prerequisites:
  - Java 1.7

Systems Supported
  - Mac OSX
  - Ubuntu


Usage:
  mobo up      - boot all devices defined in the devices.yaml file in the current directory

  mobo status  - show status of all current devices

  mobo destroy - kill all running devices


Example devices.yaml file
```yaml
---

devices:
  - name: foo
    target: android-22
  - name: bar
    target: android-22
    skin: WVGA800
```

Building from source:
```bash
gem build mobo.gemspec
gem install -l mobo-[version].gem
```
