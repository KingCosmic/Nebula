let project = new Project('Nebula');
project.addAssets('assets/**');
project.addShaders('shaders/**');
project.addSources('src');
resolve(project);