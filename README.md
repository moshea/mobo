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
