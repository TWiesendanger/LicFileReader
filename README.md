# LicFileReader

Reads Autodesk / FlexLM License Files. Maybe you already know about [LicenseFileParser](https://www.licenseparser.com/), which is a possibility to make .lic files human readable. It works and I was using it before I created this tool. Everything I didnt like I tried to do better in this tool.

So in short what are the pros for this tool?

- offline use (You dont have to upload your license file to some site)
- collapse groups (Especially usefull with the new collections that show alot of single products included)
- create screenshots
- Input Text

![](/docs/licreader_interface.png)

# Tool does not start!

[Have a look here](https://github.com/TWiesendanger/ADSKLincensingModify#tool-doesnt-start)

# Table of Contents

- [LicFileReader](#licfilereader)
- [Tool does not start!](#tool-does-not-start)
- [Table of Contents](#table-of-contents)
- [Function Demo](#function-demo)
- [Installation](#installation)
- [Start](#start)
  - [Dropped File](#dropped-file)
  - [Pasted Text](#pasted-text)
- [Read file](#read-file)
- [Collapse groups](#collapse-groups)
- [Take Screenshots](#take-screenshots)
- [Copy Infos](#copy-infos)
- [Help](#help)
- [Settings](#settings)
- [Tool doesn't start](#tool-doesnt-start)
- [License](#license)

# Function Demo

# Installation

There is no real installation needed. So even if you cannot install anything on your machine, you should be able to unzip the release and use it.
The only condition is, that you keep the folder structure.

![](/docs/licreader_structure.png)

If you need a desktop Icon, create one.

![](/docs/licreaded_createIcon.gif)

# Start

To get started you need past a license file as text or drag and drop it.

Drag and Drop accepts .txt files or .lic files. make sure that you try to drop only one.

## Dropped File

![](/docs/licreader_droppedFile.png)

## Pasted Text

![](/docs/licreader_pastedFile.png)

# Read file

If you dropped a file or pasted some text, press Read to get a human readable view of the content.

The tool will list single products in the upper part under increments and packages with its content.

![](/docs/licreader_readfilesample.png)

# Collapse groups

Packages sometimes have a lot of products that come with it. For collections this are always the same, so most of the time it is of no interest. If you double click the Packageheader it will collapse. If you repeat it, it extends again. This can be especially usefull for taking screenshots.

![](/docs/licreader_collapsed.png)

# Take Screenshots

There are two ways to take a screenshot of the whole app. There is the left option which asks you for a save path and there is the other way right next to you.
This function saves a screenshot to a predefined path.

The first time you have to define this path in the settings.

![](/docs/licreader_screenshot.png)

# Copy Infos

All the infos on the top, like servername, macadress etc. can be copied by a right click. There is a notification that says if the copy was a success.

# Help

Opens this website if you click on it.

![](/docs/licreader_help.png)

# Settings

There is just one setting at the moment and that is to set a path for the fast screenshot function.

![](/docs/licreader_settings.png)

# Tool doesn't start

At the moment it is not signed so you probably get a windows defender message which you need to allow.

![](/docs/adskm_smartscreen.png)

Also make sure that all dll files are not blocked. Open res\assembly folder and check by rightclicking on dll file.

![](/docs/adskm_blocked.jpg)

# License

MIT License

Copyright (c) 2020 Tobias Wiesendanger

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
