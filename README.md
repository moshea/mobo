### Manage your android devices easily with one yaml file.

Define, boot up and tear down android emulators with a yaml definition and simple commands. 

Performs system checks before booting each emulator and installs any android libraries that are needed to boot the emulator, including base android, android tools and android platform tools.

Prerequisites:
  - Java 1.7

Systems Supported
  - Mac OSX
  - Ubuntu

#### Install:
```bash
gem install mobo
```

```
Gemfile
gem 'mobo'
```

#### Usage:

  mobo init    - perform an initial install of android, adb and haxm. They will be installed with mobo up, but it's a convient method for scripting installations

  mobo up      - boot all devices defined in the devices.yaml file in the current directory

  mobo status  - show status of all current devices

  mobo destroy - kill all running devices

  Set DEBUG=1 to turn on debugging messages eg. 
  ```bash
  DEBUG=1 mobo up
  ```

#### Example devices.yaml file
```yaml
---

devices:
  - name: foo
    target: android-22
  - name: bar
    target: android-22
    skin: WVGA800
```

#### Configuration

Mobo creates a ~/.mobo directory, and stores all necessary libraries in there.
Android will be installed by default in that location, and used by mobo.
If you would like to use the mobo instance of android you can issue the following commands
#####
```bash
ANDROID_HOME=~/.mobo/android-sdk
PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

ANDROID_HOME and PATH can also be set in your ~/.bash_profile

#### Building from source
```bash
gem build mobo.gemspec
gem install -l mobo-[version].gem
```
