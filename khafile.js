let project = new Project('Nebula');
project.addAssets('assets/**');
project.addShaders('shaders/**');
project.addSources('src');
project.addSources('lib');
project.addParameter('--macro addGlobalMetadata("", "@:build(mixin.Mixin.sugar())", true, true, false)');
resolve(project);