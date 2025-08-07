let project = new Project('nebula');

project.addDefine('macro:tink.Await.enable');
project.addAssets('assets/**');
project.addShaders('shaders/**');
project.addSources('src');
resolve(project);