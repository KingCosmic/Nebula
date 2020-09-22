# Haxe-Phaser
This is an attempt to port phaser from js to haxe for native exports

## Usage
Unlike Phaser to use this framework you have to download this repository and code inside it.

so just download this repository, open it up and run the command

## Running in VS Code

Two extensions are required to run haxe-phaser directly from VS Code:

[Kha](https://marketplace.visualstudio.com/items?itemName=kodetech.kha)

[Kha Extension Pack](https://marketplace.visualstudio.com/items?itemName=kodetech.kha-extension-pack)

The version of Kha on the VS Code marketplace is slightly older, so it is recommended to use the latest version of the Kha framework.

## Get Latest Kha

It's recommended to follow this section if you intend to develop your application exclusively in VS Code. 

Inside the **haxe-phaser** folder, add the Kha submodule:

```
git submodule add https://github.com/Kode/Kha
```

...pull the submodule down:

```
git submodule update --init --recursive
```

You will notice there is now a Kha folder at the root level of the project. 

Move this folder to somewhere on your computer such as your home directory.

Next, you'll want to let VS Code know which version of Kha to use. 

## Updating Kha Path in VS Code

Click the Extension tab in VS Code, and look for Kha - click **Extension Settings**.

![Extension Settings](https://i.imgur.com/qMGvkpa.png)

Update the **Kha Path** to the Kha directory you downloaded earlier.

![Kha Path](https://i.imgur.com/nemSBWx.png)

## Running the Project

With your **haxe-phaser** project opened in VS Code, you will now be able to run the project. Click Run from the tabs **(Ctrl+Shift+D)** followed by the Play button to Start Debugging.

The example project will run. By default this will be an HTML5 project running in an Electron instance. 

Enjoy!

