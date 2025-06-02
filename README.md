## Tag Pivots

Tag Pivots is a simple and powerful Aseprite plugin that lets you define and manage pivot points for frame tags directly within your sprite projects.


### ✨ How does it work?
Tag Pivots adds a context menu command to Aseprite, allowing you to set, preview, and store custom pivot points for each animation tag in your sprite. This is especially useful for animators and game developers who need consistent anchor points for actions like flipping, rotating, or aligning sprites in their workflow.

### 🚀 Features & Highlights
**Easy Pivot Assignment:**
Quickly set a pivot point for any tag using a visual dialog with live preview.

**Preset Positions:**
Choose from common pivot presets (center, corners, edges) or enter custom coordinates.

**Per-Tag Storage:**
Each tag’s pivot is stored as custom data, making it easy to retrieve and use in your pipeline.

**Live Preview:**
Instantly see your pivot placement on the sprite before saving.

**Context Menu Integration:**
Access the pivot setter directly from the tag context menu for a smooth workflow.

**Safe & Non-Destructive:**
All pivots are stored as metadata—your artwork remains untouched.

**Open Source & Extensible:**
Licensed under CC-BY-4.0 and easy to modify for your own needs.

**🛠️ Getting Started**
1. Download the zip file from the latest release in this repository
2. Add the zip as an extension into Aseprite.
3. Right-click a tag in the timeline and select `Set Pivot Point`
4. Currently, the data is stored under [user-defined properties](https://aseprite.org/api/properties#properties) for the tag object. To access this data from the exported JSON, this change will be required:
https://github.com/aseprite/aseprite/pull/5187

Enjoy smoother animation workflows with Tag Pivots!

Feedback and contributions are welcome.
