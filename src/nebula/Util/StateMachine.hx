package nebula.Util;

interface State<TData> {
  name?: String;
  transitions: String[];
  onEnter?: (context: { from: String; eventData?: dynamic; data: TData }) => Null<Bool>;
  onState?: () => dynamic;
  onExit?: (context: { to: String; data: TData }) => Null<Bool>;
  onUpdate?: (data: TData, elapsed: Int) => any;
}

interface StateMachineDescription<TData = dynamic> {
  start: String;
  states: { [name: String]: State<TData> };
}

type PossibleStates<TMachine> = TMachine extends StateMachineDescription ? Extract<keyof TMachine['states'], String> : never;

interface StateMachineState<TData> {
  data: TData;
  currentState: String;
}

class StateMachine<TPossibleStates extends String, TData> {
  public startState: State<TData>;
  private _currentState: State<TData>;
  public get currentState(): State<TData> {
    return this._currentState;
  }
  public set currentState(state: State<TData>) {
    this._currentState = state;
  }
  public states = new Map<String, State<TData>>();
  public data: TData;

  static create<TMachine extends StateMachineDescription<TData>, TData>(
    machineDescription: TMachine,
    data?: TData
  ): StateMachine<PossibleStates<TMachine>, TData> {
    final machine = new StateMachine<PossibleStates<TMachine>, TData>();
    machine.data = data;
    for (final stateName in machineDescription.states) {
      machine.states.set(stateName as PossibleStates<TMachine>, {
        name: stateName,
        ...machineDescription.states[stateName]
      });
    }

    // validate transitions are states
    for (final state of machine.states.values()) {
      for (final transitionState of state.transitions) {
        if (transitionState === '*') {
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

  in(state: TPossibleStates): Bool {
    return this.currentState.name === state;
  }

  go(stateName: TPossibleStates, eventData?: dynamic): Bool {
    if (this.currentState.transitions.includes(stateName) || this.currentState.transitions.includes('*')) {
      final potentialNewState = this.states.get(stateName);
      if (this.currentState.onExit) {
        final canExit = this.currentState?.onExit({ to: potentialNewState.name, data: this.data });
        if (canExit === false) {
          return false;
        }
      }

      if (potentialNewState?.onEnter) {
        final canEnter = potentialNewState?.onEnter({ from: this.currentState.name, eventData, data: this.data });
        if (canEnter === false) {
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

  update(elapsed: Int) {
    if (this.currentState.onUpdate) {
      this.currentState.onUpdate(this.data, elapsed);
    }
  }

  save(saveKey: String) {
    // TODO: fix this.
    // localStorage.setItem(
    //   saveKey,
    //   JSON.stringify({
    //     currentState: this.currentState.name,
    //     data: this.data
    //   })
    // );
  }

  restore(saveKey: String) {
    // final state: StateMachineState<TData> = JSON.parse(localStorage.getItem(saveKey));
    // this.currentState = this.states.get(state.currentState);
    // this.data = state.data;
  }
}
