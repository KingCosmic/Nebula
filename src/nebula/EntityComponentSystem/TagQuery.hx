package nebula.entitycomponentsystem;

import nebula.util.Observable;

import nebula.entitycomponentsystem.Entity;

class TagQuery {
  public var id: String;
  public var tags = new Map<TKnownTags, Bool>();
  public var entities: Array<Entity<Any>> = [];
  /**
   * This fires right after the component is added
   */
  public var entityAdded = new Observable<Entity<Any>>();
  /**
   * This fires right before the component is actually removed from the entity, it will still be available for cleanup purposes
   */
  public var entityRemoved = new Observable<Entity<Any>>();

  public function new(requiredTags: Array<String>) {
    if (requiredTags.length == 0) {
      throw new Error('Cannot create tag query without tags');
    }
    for (tag in requiredTags) {
      this.tags.add(tag);
    }

    this.id = TagQuery.createId(requiredTags);
  }

  static function createId(requiredComponents: Array<String>) {
    return requiredComponents.slice().sort().join('-');
  }

  function checkAndAdd(entity: Entity): Bool {
    if (!this.entities.includes(entity) && entity.hasAllTags(Array.from(this.tags))) {
      this.entities.push(entity);
      this.entityAdded.notifyAll(entity);
      return true;
    }
    return false;
  }

  function removeEntity(entity: Entity) {
    final index = this.entities.indexOf(entity);
    if (index > -1) {
      this.entities.splice(index, 1);
      this.entityRemoved.notifyAll(entity);
    }
  }

  /**
   * Returns a list of entities that match the query
   * @param sort Optional sorting function to sort entities returned from the query
   */
  public function getEntities(sort: Null<(a: Entity, b: Entity) -> Int>): Array<Entity<Any>> {
    if (sort) {
      this.entities.sort(sort);
    }
    return this.entities;
  }
}
