let project = new Project('Nebula');

project.addLibrary('nape-haxe4');

project.addAssets('assets/**');
project.addShaders('shaders/**');
project.addSources('src');
resolve(project);