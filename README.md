# Nebula
This is a 2D engine using kha. Primarily for personal use.

## Usage
To start follow setting up Kha, then add this repo as a submodule aswell.

```
git submodule add https://github.com/KingCosmic/Nebula
```

...then initialize the submodule:

```
git submodule update --init --recursive
```

Last but not least, open up khafile.js and add this ass a subproject

(your's should look something like this)
```js
let project = new Project('Example Of Stuff');
await project.addProject('Nebula');
project.addAssets('assets/**');
project.addShaders('shaders/**');
project.addSources('src');
resolve(project);
```

## Updating

just run this command!

```
git submodule update --remote
```

Enjoy!

## Examples
We do not yet have examples sadly.

## Questions?
Feel free to contact me on discord at KingCosmic#9311