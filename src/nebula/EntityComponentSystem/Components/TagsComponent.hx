package nebula.EntityComponentSystem.Components;

import nebula.EntityComponentSystem.Component;

class TagsComponent extends Component {
  public tags = new Set<String>();
}
