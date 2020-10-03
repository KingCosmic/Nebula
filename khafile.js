let project = new Project('New Project');
project.addAssets('Assets/**');
project.addShaders('Shaders/**');
project.addSources('Sources');
project.addSources('mixin/lib');
project.addParameter('--macro addGlobalMetadata("", "@:build(mixin.Mixin.sugar())", true, true, false)');
resolve(project);
