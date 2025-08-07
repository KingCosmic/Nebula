package nebula.util;

interface State<TData> {
  var name: Null<String>;
  var transitions: Array<String>;
  function onEnter(context: { from: String, eventData: Null<Any>, data: TData }): Null<Bool>;
  onState: Null<() -> Any>;
  onExit: Null<(context: { to: String; data: TData }) -> Null<Bool>>;
  onUpdate: Null<(data: TData, elapsed: Int) -> Any>;
}

interface StateMachineDescription<TData> {
  start: String;
  states: { [name: String]: State<TData> };
}

interface StateMachineState<TData> {
  data: TData;
  currentState: String;
}

class StateMachine<TData> {
  public var startState: State<TData>;
  private var _currentState: State<TData>;

  public var currentState(get, set): State<TData>;
  function get_currentState(): State<TData> {
    return this._currentState;
  }
  function set_currentState(state: State<TData>) {
    this._currentState = state;
  }

  public var states = new Map<String, State<TData>>();
  public var data: TData;

  static function create<TData>(
    machineDescription: StateMachineDescription<TData>,
    ?data: TData
  ): StateMachine<TData> {
    final machine = new StateMachine<TData>();
    machine.data = data;
    for (stateName in machineDescription.states) {
      var state = Object.spreadWith({ name: stateName }, machineDescription.states[stateName]);
      machine.states.set(stateName, state);
    }

    // validate transitions are states
    for (state in machine.states.values()) {
      for (transitionState in state.transitions) {
        if (transitionState == '*') {
          continue;
        }
        if (!machine.states.has(transitionState)) {
          throw Error(
            'Invalid state machine, state [${state.name}] has a transition to another state that doesn\'t exist [${transitionState}]'
          );
        }
      }
    }
    machine.currentState = machine.startState = machine.states.get(machineDescription.start);
    return machine;
  }

  function in(state: TPossibleStates): Bool {
    return this.currentState.name == state;
  }

  function go(stateName: TPossibleStates, ?eventData: Any): Bool {
    if (this.currentState.transitions.includes(stateName) || this.currentState.transitions.includes('*')) {
      final potentialNewState = this.states.get(stateName);
      if (this.currentState.onExit) {
        final canExit = this.currentState?.onExit({ to: potentialNewState.name, data: this.data });
        if (canExit == false) {
          return false;
        }
      }

      if (potentialNewState?.onEnter) {
        final canEnter = potentialNewState?.onEnter({ from: this.currentState.name, eventData, data: this.data });
        if (canEnter == false) {
          return false;
        }
      }
      this.currentState = potentialNewState;
      if (this.currentState?.onState) {
        this.currentState.onState();
      }
      return true;
    }
    return false;
  }

  function update(elapsed: Int) {
    if (this.currentState.onUpdate) {
      this.currentState.onUpdate(this.data, elapsed);
    }
  }

  function save(saveKey: String) {
    // TODO: fix this.
    // localStorage.setItem(
    //   saveKey,
    //   JSON.stringify({
    //     currentState: this.currentState.name,
    //     data: this.data
    //   })
    // );
  }

  function restore(saveKey: String) {
    // final state: StateMachineState<TData> = JSON.parse(localStorage.getItem(saveKey));
    // this.currentState = this.states.get(state.currentState);
    // this.data = state.data;
  }
}
