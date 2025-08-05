let project = new Project('nebula');

project.addAssets('assets/**');
project.addShaders('shaders/**');
project.addSources('src');
resolve(project);