package core.gameobjects.components;

/**
 * Provides methods used for setting the WebGL rendering pipeline of a Game Object.
 */
// To-Do Is this even needed for kha?...//
@mixin interface Pipeline {
	/**
	 * The initial WebGL pipeline of this Game Object.
	 */
	public var defaultPipeline:{name:String} = {name: "initPipeline"}; // Phaser.Renderer.WebGL.WebGLPipelin WEBGL ONLY

	/**
	 * The current WebGL pipeline of this Game Object.
	 */
	public var pipeline:{name:String} = null; // Phaser.Renderer.WebGL.WebGLPipeline WEBGL ONLY

	/**
	 * Sets the initial WebGL Pipeline of this Game Object.
	 *
	 * This should only be called during the instantiation of the Game Object.
	 */
	public function initPipeline(name:String = "initPipeline"):Bool { // WEBGL ONLY, is this required?
		/*
				var renderer = this.scene.sys.game.renderer;
				var pipelines = renderer.pipelines;
				if (pipelines && pipelines.has(name)){
					this.defaultPipeline = pipelines.get(name);
					this.pipeline = this.defaultPipeline;

					return true;
		}*/ // To-Do

		return false;
	}

	/**
	 * Sets the active WebGL Pipeline of this Game Object.
	 */
	public function setPipeline(name:String):GameObject {
		/*
			var renderer = this.scene.sys.game.renderer;
			var pipelines = renderer.pipelines;

			if (pipelines && pipelines.has(name))
			{
				this.pipeline = pipelines.get(name);
			}
		 */ // To-Do

		return this;
	}

	/**
	 * Resets the WebGL Pipeline of this Game Object back to the default it was created with.
	 */
	public function resetPipeline():Bool {
		this.pipeline = this.defaultPipeline;

		return (this.pipeline != null);
	}

	/**
	 * Gets the name of the WebGL Pipeline this Game Object is currently using.
	 */
	public function getPipelineName():String {
		return this.pipeline.name;
	}
}