# PowerBoost Magisk Module

## **Description:**
PowerBoost is a Magisk module designed to enhance battery life by optimizing power consumption on your Android device. It achieves this by adjusting system parameters like CPU frequencies, screen timeout settings, and disabling unused sensors, all of which help reduce power usage without sacrificing performance. This module is ideal for users who want to maximize their device's battery life while maintaining a smooth user experience.

### **Key Features:**
- **Lower CPU Frequencies**: Automatically reduces CPU frequencies when the device is idle, helping save battery by keeping the device in a power-efficient state.
- **Reduce Screen Timeout**: Decreases the screen timeout setting to ensure the display turns off sooner, thus conserving battery when the device is not actively in use.
- **Disable Unused Sensors and Features**: Disables sensors or system features that are not in use, such as USB tethering, to further reduce power consumption.
- **Easy Installation**: The module is easy to install through Magisk Manager with a simple ZIP file flash.

---

## **Installation Instructions:**
1. **Download the Module:**
   - Go to the **[Releases](https://github.com/Yusuf6411/PowerBoost-magisk/releases)** section of this repository and download the latest `PowerBoost.zip` file.

2. **Install via Magisk Manager:**
   - Open **Magisk Manager** on your Android device.
   - Navigate to the **Modules** tab.
   - Tap on **Install from Zip**.
   - Select the `PowerBoost.zip` file you downloaded.
   - Magisk will automatically install the module and apply the necessary changes.

3. **Reboot the Device:**
   - Once the installation is complete, reboot your device to activate the module.

---

## **Uninstallation Instructions:**
1. Open **Magisk Manager** and go to the **Modules** section.
2. Find the **PowerBoost** module in the list.
3. Tap **Remove** next to the module.
4. After the module is uninstalled, reboot your device to restore the previous settings.

---

## **Customization:**
- The module’s script (`99powerboost.sh`) can be customized for additional power-saving features. If you are experienced with shell scripting, you can modify this script to tweak more system settings according to your preferences.

---

## **Compatibility:**
- This module is compatible with any Android device running Magisk. It is generally device-agnostic but may work better on devices with certain processors or screen settings. 
- Devices with custom ROMs may require additional testing.

---

## **Benefits:**
- **Improved Battery Life**: By reducing unnecessary background processes and adjusting system settings, your device will use less power, providing more screen-on time.
- **Optimal Performance**: Although the module reduces power usage, it does so in a way that does not significantly impact the overall performance of the device.
- **Customizable Power Settings**: Tailor the power-saving options to suit your specific device or usage pattern.

---

## **Why Use PowerBoost?**
If you’re someone who uses their Android device extensively throughout the day, battery life becomes a concern. PowerBoost addresses this by applying intelligent tweaks that automatically adjust the system when it's not in use, ensuring that your device remains efficient and lasts longer on a single charge.

---

## **Notes:**
- PowerBoost uses several common tweaks to reduce power usage, including setting the CPU scaling governor to "powersave," lowering the CPU's minimum frequency during idle times, and disabling non-essential sensors and features. These changes are safe and reversible, but if you notice any issues, you can uninstall the module at any time.
- The power-saving changes apply system-wide, which means you’ll see the benefits across all apps and activities.

---

## **Known Issues:**
- On certain devices, some tweaks (such as screen timeout) might conflict with specific ROM features or settings. If you encounter issues, you can disable certain tweaks by editing the script (`99powerboost.sh`).

---

## **License:**
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## **Credits:**
- **Author**: Yusuf Mohammed
