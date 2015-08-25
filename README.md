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
    height: 1200
    width: 720
  - name: bar
    target: android-22
    height: 800
    width: 600
```
