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

Mobo looks for the environment variable ANDROID_HOME, and checks if android is installed.
If ANDROID_HOME isn't defined, Mobo will download and install Android from scratch. Only installing the minimum libraries needed.
Mobo will then set ANDROID_HOME and add ANDROID_HOME/tools and ANDROID_HOME/platform-tools to the PATH so that it is accessable from the console.
A terminal session might need to be restarted for the changes to take effect.


Mobo installs Android in /usr/local/<android-sdk-name> as default

#### Building from source
```bash
gem build mobo.gemspec
gem install -l mobo-[version].gem
```
