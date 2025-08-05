package nebula.Math;

import nebula.Math.Random;
import nebula.Math.Vector;

/**
 * A unique identifier for a graph node or edge.
 */
type G_UUID = String & { readonly __brand: unique symbol };

interface EdgeOptionsWithWeight {
  weight: Int;
  useEuclidean?: false;
  /**
   * Whether the edge is directed.
   * @default false
   */
  directed?: Bool;
}

interface EdgeOptionsWeightless {
  weight?: undefined;
  useEuclidean?: false | undefined;
  /**
   * Whether the edge is directed.
   * @default false
   */
  directed?: Bool;
}

interface EdgeOptionsWithEuclidean {
  weight?: undefined;
  useEuclidean: true;
  /**
   * Whether the edge is directed.
   * @default false
   */
  directed?: Bool;
}

/**
 * Options for creating a new edge in the graph.
 */
type EdgeOptions = EdgeOptionsWithWeight | EdgeOptionsWithEuclidean | EdgeOptionsWeightless;

/**
 * A weighted graph data structure.
 * @template T The type of data stored in each node.
 */
class Graph<T> {
  private _nodes: Map<G_UUID, Node<T>>;
  private _edges: Set<Edge<T>>;
  adjacencyList: Map<G_UUID, Set<G_UUID>>;
  id: G_UUID = GraphUUId.generateUUID();

  /**
   * Constructs a new graph data structure.
   *
   * This constructor initializes an empty graph with no nodes or edges.
   */
  public function new() {
    this._nodes = new Map();
    this._edges = new Set();
    this.adjacencyList = new Map();
  }

  /**
   * Adds a new node to the graph with the given data.
   * @returns The newly created node.
   */
  addNode(data: T, position?: Vector): Node<T> | PositionNode<T> {
    var newNode;
    if (position) {
      newNode = new PositionNode(data, position);
    } else {
      newNode = new Node(data);
    }
    this._nodes.set(newNode.id, newNode);
    this.adjacencyList.set(newNode.id, new Set());
    return newNode;
  }

  /**
   * Adds multiple new nodes to the graph with the given data.
   * @returns A map of all nodes in the graph, including the newly created ones.
   */
  addNodes(nodes: T[]): Map<G_UUID, Node<T>> {
    for (final node of nodes) {
      final thisNewNode = new Node(node);
      this._nodes.set(thisNewNode.id, thisNewNode);
      this.adjacencyList.set(thisNewNode.id, new Set());
    }
    return this._nodes;
  }

  /**
   * Deletes a node from the graph along with all its associated edges.
   * This method removes the specified node and any edges connected to it
   * from the graph. It updates the internal structures to reflect these
   * changes.
   * @param node - The node to be deleted from the graph.
   * @returns A map of all remaining nodes in the graph.
   */
  deleteNode(node: Node<T>): Map<G_UUID, Node<T>> {
    //delete any edges tied to node
    final nodeEdges = node.edges;
    for (final edge of nodeEdges) {
      this.deleteEdge(edge);
    }

    this.adjacencyList.forEach((value, key) => {
      value.delete(node.id);
    });

    this._nodes.delete(node.id);
    this.adjacencyList.delete(node.id);
    return this._nodes;
  }

  /**
   * Adds a new edge between two nodes in the graph. If the edge already exists, it does not add a duplicate.
   * The function allows specifying edge options such as weight and directionality. For undirected edges,
   * it creates a duplicate edge in the reverse direction and links both edges as partners.
   * @param from - The source node of the edge.
   * @param to - The target node of the edge.
   * @param options - Optional settings for the edge, including weight and directionality.
   * @returns An array containing the created edge(s). If the edge is directed, the array contains one edge;
   *          if undirected, it contains both the original and the duplicate edge.
   */

  addEdge(from: Node<T>, to: Node<T>, options?: EdgeOptions): Edge<T>[] {
    //gaurd clauses
    final existingEdges = Array.from(this._edges).find((edge) => edge.source.id === from.id && edge.target.id === to.id);
    if (existingEdges) {
      return [];
    }

    var directed;

    if (options) {
      directed = 'directed' in options ? options.directed : false;
    } else {
      directed = false;
    }

    final newEdge = new Edge(from, to, options);

    this._edges.add(newEdge);
    from.registerNewEdge(newEdge);
    to.registerNewEdge(newEdge);
    this.adjacencyList.get(from.id)?.add(to.id);

    if (!directed) {
      final duplicateEdge = new Edge(to, from, options);
      this.adjacencyList.get(to.id)?.add(from.id);
      this._edges.add(duplicateEdge);
      to.registerNewEdge(duplicateEdge);
      from.registerNewEdge(duplicateEdge);
      //link the two edges together
      newEdge.linkWithPartner(duplicateEdge);
      duplicateEdge.linkWithPartner(newEdge);
      return [newEdge, duplicateEdge];
    }
    return [newEdge];
  }

  /**
   * Deletes an edge from the graph.
   *
   * This method removes the specified edge and its partner edge (if any) from the graph.
   * It updates the internal edge set and edge list accordingly. The source and target
   * nodes of the edge are also updated to reflect the removal of the edge.
   * @param edge - The edge to be deleted from the graph.
   */

  deleteEdge(edge: Edge<T>) {
    edge.source.breakEdge(edge);
    edge.target.breakEdge(edge);
    this._edges.delete(edge);

    final partnerEdge = edge.partnerEdge;
    if (partnerEdge) {
      partnerEdge.source.breakEdge(partnerEdge);
      partnerEdge.target.breakEdge(partnerEdge);
      this._edges.delete(partnerEdge);
    }
  }

  /**
   * The set of nodes in the graph, keyed by their UUID.
   *
   * The map returned by this property is a shallow copy of the internal map.
   * The nodes in this map are not frozen, and may be modified by the caller.
   * @returns A shallow copy of the graph's internal node map.
   */
  get nodes(): Map<G_UUID, Node<T>> {
    return this._nodes;
  }

  /**
   * Gets a node by its UUID.
   * @param id - The UUID of the node to be retrieved.
   * @returns The node with the specified UUID, or undefined if no such node exists.
   */
  getNode(id: G_UUID): Node<T> {
    return this._nodes.get(id)!;
  }

  /**
   * Retrieves the set of edges in the graph.
   *
   * The returned set is a shallow copy of the internal edge set.
   * Modifications to this set do not affect the graph's internal state.
   * @returns A set containing all edges in the graph.
   */
  get edges(): Set<Edge<T>> {
    return this._edges;
  }

  /**
   * Gets the neighbors of the given node.
   *
   * The returned array contains all of the nodes that are directly connected to the given node.
   * @param node - The node whose neighbors should be retrieved.
   * @returns An array of nodes that are directly connected to the given node.
   */
  getNeighbors(node: Node<T>): Node<T>[] {
    return Array.from(this.adjacencyList.get(node.id) ?? []).map((nid) => this.nodes.get(nid)!);
  }

  /**
   * Checks if two nodes are connected by an edge.
   * @param node1 - The first node to check.
   * @param node2 - The second node to check.
   * @returns true if the nodes are connected, false if not.
   */
  areNodesConnected(node1: Node<T>, node2: Node<T>): Bool {
    return this.adjacencyList.get(node1.id)?.has(node2.id) ?? false;
  }

  /**
   * Performs a breadth-first search (BFS) on the graph starting from the given node.
   *
   * This method explores the graph layer by layer, starting from the specified node.
   * It visits all nodes that are directly connected to the start node before moving
   * on to the nodes at the next level of the graph.
   * @param startNode - The node to start the BFS from.
   * @returns An array of UUIDs representing the nodes that were visited during the search.
   *          The order of the nodes in the array corresponds to the order in which they
   *          were visited.
   */
  bfs(startNode: Node<T>): G_UUID[] {
    // Verify the start node exists in the graph
    if (!this._nodes.has(startNode.id)) {
      return [];
    }

    final queue: G_UUID[] = [startNode.id];
    final visited: Set<G_UUID> = new Set([startNode.id]);

    while (queue.length > 0) {
      final nodeId = queue.shift()!;
      final neighbors = this.adjacencyList.get(nodeId) || new Set();
      for (final neighborId of neighbors) {
        if (!visited.has(neighborId)) {
          visited.add(neighborId);
          queue.push(neighborId);
        }
      }
    }
    return Array.from(visited);
  }

  /**
   * Performs a depth-first search (DFS) on the graph starting from the given node.
   *
   * This method explores the graph by traversing as far as possible along each
   * branch before backtracking. It visits all nodes that are reachable from the
   * start node.
   * @param startNode - The node to start the DFS from.
   * @param [visited] - A set of node IDs that have already been visited during
   *                    the search. This parameter is optional, and defaults to an
   *                    empty set.
   * @returns An array of UUIDs representing the nodes that were visited during the
   *          search. The order of the nodes in the array corresponds to the order
   *          in which they were visited.
   */
  dfs(startNode: Node<T>, visited: Set<string> = new Set()): G_UUID[] {
    final startId: G_UUID = startNode.id;
    if (!this._nodes.has(startId)) {
      return [];
    } // Invalid start node

    visited.add(startId);
    var result: G_UUID[] = [startId];

    for (final neighbor of this.adjacencyList.get(startId) ?? []) {
      if (!visited.has(neighbor)) {
        result = result.concat(this.dfs(this._nodes.get(neighbor)!, visited));
      }
    }
    return result;
  }

  /**
   * Creates a new graph from an array of nodes, and adds them all to the graph.
   * @param nodes - The array of nodes to add to the graph.
   * @returns The newly created graph.
   */
  static createGraphFromNodes<T>(nodes: T[]): Graph<T> {
    final graph = new Graph<T>();
    graph.addNodes(nodes);
    return graph;
  }

  /**
   * Finds the shortest path between two nodes in the graph using Dijkstra's algorithm.
   *
   * This method calculates the shortest path from the specified start node to the
   * specified end node in the graph. It returns an object containing the path and
   * the total distance of the path.
   * @param startNode - The node from which the search for the shortest path begins.
   * @param endNode - The node where the search for the shortest path ends.
   * @returns An object containing:
   *   - `path`: An array of nodes representing the shortest path from startNode to endNode.
   *     If no path is found, this will be `null`.
   *   - `distance`: The total distance of the shortest path. If no path is found, this will
   *     be `Infinity`.
   */

  dijkstra(sourcenode: Node<T>): Array<{ node: Node<T>; distance: Int; previous: Null<Node<T>> }> {
    final visited: Node<T>[] = [];
    final unvisited: Node<T>[] = [];
    final resultArray: Array<{ node: Node<T>; distance: Int; previous: Null<Node<T>> }> = [];

    //fill unvisited
    this.nodes.forEach((node) => unvisited.push(node));

    //fill resultArray
    this.nodes.forEach((node) => resultArray.push({ node, distance: Infinity, previous: null }));

    //start with starting node
    //add startingnode to result array
    final startingNodeIndex = resultArray.findIndex((node) => node.node === sourcenode);
    if (startingNodeIndex === -1) {
      return [];
    }
    resultArray[startingNodeIndex].distance = 0;

    visited.push(sourcenode);
    unvisited.splice(unvisited.indexOf(sourcenode), 1);

    var current = sourcenode;
    final currentEdges = current.edges;
    final filteredCurrentEdges: Edge<T>[] = Array.from(currentEdges).filter((edge: Edge<T>) => edge.target !== current);

    //update result array with distances, which is edge values

    for (final edge of filteredCurrentEdges) {
      final index = resultArray.findIndex((node) => node.node === edge.target);

      if (index === -1) {
        return [];
      }
      resultArray[index].distance = edge.weight as number;
      resultArray[index].previous = current;
    }

    while (unvisited.length > 0) {
      //get list of unvisited available nodes
      var listOfAvailableNodes: Node<T>[] = [];
      ar listofAvailableEntries: Array<{ node: Node<T>; distance: Int; previous: Node<T> | null }> = [];
      listofAvailableEntries = resultArray.filter((node) => unvisited.includes(node.node));
      listOfAvailableNodes = listofAvailableEntries.map((node) => node.node);

      //loop through available nodes and find lowest distance to sourcenode
      var lowestDistance = Infinity;
      var lowestDistanceIndex = -1;

      if (listOfAvailableNodes.length > 0) {
        for (var i = 0; i < listOfAvailableNodes.length; i++) {
          final unVisitiedNode = listOfAvailableNodes[i];

          final index = resultArray.findIndex((node) => node.node === unVisitiedNode);
          if (resultArray[index].distance < lowestDistance) {
            lowestDistance = resultArray[index].distance;
            lowestDistanceIndex = index;
          }
        }
      } else {
        //manage exception
        //choose node from unvisited list that has lowest distance to source node

        lowestDistance = Infinity;
        lowestDistanceIndex = -1;
        for (var i = 0; i < unvisited.length; i++) {
          final unVisitiedNode = unvisited[i];
          final index = resultArray.findIndex((node) => node.node === unVisitiedNode);
          if (resultArray[index].distance < lowestDistance) {
            lowestDistance = resultArray[index].distance;
            lowestDistanceIndex = index;
          }
        }
      }

      if (lowestDistanceIndex === -1) {
        return [];
      }

      current = resultArray[lowestDistanceIndex].node;
      var currentEdgesArray = Array.from(current.edges);

      //remove visited from currentEdges
      currentEdgesArray = currentEdgesArray.filter((edge: Edge<T>) => {
        return !visited.includes(edge.source) && !visited.includes(edge.target) && edge.target !== current;
      });

      visited.push(current);
      unvisited.splice(unvisited.indexOf(current), 1);

      //update result array with distances, which is edge values
      for (var i = 0; i < currentEdgesArray.length; i++) {
        final edge = currentEdgesArray[i];
        final index = resultArray.findIndex((node) => node.node === edge.target);

        //update cumulative distances
        final previousIndex = resultArray.findIndex((node) => node.node === edge.source);

        final previousDistance = resultArray[previousIndex].distance;
        final cumDistance = (previousDistance + edge.weight!) as number;

        if (cumDistance < resultArray[index].distance) {
          resultArray[index].distance = cumDistance;
          resultArray[index].previous = current;
        }
      }
    }

    return resultArray;
  }

  /**
   * Finds the shortest path between two nodes in the graph using the Dijkstra method
   *
   * This method calculates the shortest path from the specified start node to the
   * specified end node in the graph. It returns an object containing the path and
   * the total distance of the path.
   * @param startingNode - The node from which the search for the shortest path begins.
   * @param endNode - The node where the search for the shortest path ends.
   * @returns An object containing:
   *   - `path`: An array of nodes representing the shortest path from startNode to endNode.
   *     If no path is found, this will be `null`.
   *   - `distance`: The total distance of the shortest path. If no path is found, this will
   *     be `Infinity`.
   */
  shortestPathDijkstra(startingNode: Node<T>, endNode: Node<T>): { path: Node<T>[]; distance: Int } {
    final dAnalysis = this.dijkstra(startingNode);

    if (dAnalysis.length === 0) {
      return { path: [], distance: Infinity };
    }
    //iterate through dAnalysis to plot shortest path to endnode
    final path: Node<T>[] = [];
    var current: Null<Node<T>> = endNode;
    final distance = dAnalysis.find((node) => node.node === endNode)?.distance as Int;

    while (current != null) {
      path.push(current);

      current = dAnalysis.find((node) => node.node === current)?.previous;

      if (current == null) {
        break;
      }
    }
    path.reverse();
    return { path, distance };
  }

  /**
   * Finds the shortest path between two nodes in the graph using the A* algorithm.
   *
   * This method calculates the shortest path from the specified start node to the
   * specified end node in the graph. It returns an object containing the path and
   * the total distance of the path.
   * @param startNode - The node from which the search for the shortest path begins.
   * @param endNode - The node where the search for the shortest path ends.
   * @returns An object containing:
   *   - `path`: An array of nodes representing the shortest path from startNode to endNode.
   *     If no path is found, this will be `null`.
   *   - `distance`: The total distance of the shortest path. If no path is found, this will
   *     be `Infinity`.
   *   - `skippedNodes`: A set of all nodes that were skipped during the search (because they
   *     were not `PositionNode`s).
   */
  aStar(
    startNode: PositionNode<T>,
    endNode: PositionNode<T>
  ): {
    path: PositionNode<T>[] | null;
    pathSteps: Int;
    distance: Int;
    skippedNodes: Set<G_UUID>;
  } {
    // Make sure we're working with PositionNodes
    if (!('pos' in startNode) || !('pos' in endNode)) {
      throw new Error('A* algorithm requires PositionNode with position vectors');
    }

    // Initialize data structures
    final openSet: Set<G_UUID> = new Set([startNode.id]);
    final closedSet: Set<G_UUID> = new Set();
    final skippedNodes: Set<G_UUID> = new Set();

    // Track g scores (distance from start) and f scores (estimated total cost)
    final gScore: Map<G_UUID, Int> = new Map();
    final hScore: Map<G_UUID, Int> = new Map();
    final fScore: Map<G_UUID, Int> = new Map();

    // Track the path
    final cameFrom: Map<G_UUID, G_UUID | null> = new Map();

    // Initialize scores

    //remap positionNodes from this._nodes where node is type of PositionNode
    final positionNodes: Map<G_UUID, PositionNode<T>> = new Map();
    for (final [nodeId, node] of this._nodes) {
      if ('pos' in node) {
        positionNodes.set(nodeId, node as PositionNode<T>);
      } else {
        skippedNodes.add(nodeId);
      }
    }

    for (final [nodeId] of positionNodes) {
      gScore.set(nodeId, this._euclideanDistance(positionNodes.get(nodeId)!, startNode));
      hScore.set(nodeId, this._euclideanDistance(positionNodes.get(nodeId)!, endNode));
      fScore.set(nodeId, gScore.get(nodeId)! + hScore.get(nodeId)!);
      cameFrom.set(nodeId, null);
    }

    // Continue until we've visited all nodes or found the target
    while (openSet.size > 0) {
      // Find node with lowest fScore
      var currentId: G_UUID | null = null;
      var lowestFScore = Infinity;

      for (final nodeId of openSet) {
        final score = fScore.get(nodeId) || Infinity;
        if (score < lowestFScore) {
          lowestFScore = score;
          currentId = nodeId;
        }
      }

      // If we can't find a node, there's no path
      if (currentId === null) {
        break;
      }

      // If we found the target, we're done
      if (currentId === endNode.id) {
        // Reconstruct path
        final path: PositionNode<T>[] = [];
        var current: G_UUID | null = endNode.id;

        while (current !== null) {
          final node = this._nodes.get(current)! as PositionNode<T>;
          path.unshift(node);
          current = cameFrom.get(current)!;
        }

        return {
          path,
          pathSteps: path.length - 1,
          distance: gScore.get(endNode.id) || Infinity,
          skippedNodes
        };
      }

      // Move from open to closed set
      openSet.delete(currentId);
      closedSet.add(currentId);

      // Get current node
      final currentNode = this._nodes.get(currentId)! as PositionNode<T>;

      // Check all neighbors
      final neighbors = this.getNeighbors(currentNode);

      for (final neighbor of neighbors) {
        final neighborId = neighbor.id;

        // Skip if neighbor has been processed
        if (closedSet.has(neighborId)) {
          continue;
        }

        // Ensure neighbor is a PositionNode
        final positionNeighbor = neighbor as PositionNode<T>;
        if (!('pos' in positionNeighbor)) {
          continue;
        }

        // Find the edge connecting current to neighbor
        final edge: Edge<T> = Array.from(currentNode.edges).find((e: Edge<T>) => e.source.id === currentId && e.target.id === neighborId);

        if (!edge) {
          continue;
        }

        cameFrom.set(neighborId, currentId);
        // Add to open set if not already there
        if (!openSet.has(neighborId)) {
          openSet.add(neighborId);
        }
      }
    }

    // No path found
    return { path: [], pathSteps: 0, distance: Infinity, skippedNodes };
  }

  private _euclideanDistance(currentNode: PositionNode<T>, testNode: PositionNode<T>): Float {
    final a = currentNode.pos;
    final b = testNode.pos;
    return Math.sqrt((b.x - a.x) ** 2 + (b.y - a.y) ** 2);
  }
}

/**
 * Represents an edge in a graph, connecting two nodes.
 * @template T The type of data stored in the nodes connected by this edge.
 */
class Edge<T> {
  private _id: G_UUID = GraphUUId.generateUUID();
  private _source: Node<T>;
  private _target: Node<T>;
  private _weight: Int = 0;
  private _partnerEdge: Null<Edge<T>> = null; // Reference to the opposite direction edge

  public function new(source: Node<T>, target: Node<T>, config?: EdgeOptions) {
    this._source = source;
    this._target = target;
    if (config && config.weight) {
      this._weight = config.weight;
    } else if (config && config.useEuclidean) {
      this._weight = (source as PositionNode<T>).pos.distance((target as PositionNode<T>).pos); //calc weight
    } else {
      this._weight = 0;
    }
  }

  linkWithPartner(partnerEdge: Edge<T>): Void {
    this._partnerEdge = partnerEdge;
  }

  get id() {
    return this._id;
  }

  get source() {
    return this._source;
  }

  get target() {
    return this._target;
  }

  get weight() {
    return this._weight;
  }

  get partnerEdge() {
    return this._partnerEdge;
  }
}

/**
 * Represents a node in a graph, with a unique identifier and optional data.
 * @template T The type of data stored in this node.
 */
class Node<T> {
  private _id: G_UUID = GraphUUId.generateUUID();
  private _data: T;
  private _edges: Set<Edge<T>>;

  public function new(data: T) {
    this._data = data;
    this._edges = new Set();
  }

  get id(): G_UUID {
    return this._id;
  }

  get data() {
    return this._data;
  }

  get edges() {
    return this._edges;
  }

  registerNewEdge(newEdge: Edge<T>) {
    this._edges.add(newEdge);
  }

  breakEdge(edge: Edge<T>) {
    this._edges.delete(edge);
  }

  getConnectedNodes(): Node<T>[] {
    return Array.from(this._edges).map((edge) => edge.target);
  }
}

/**
 * Represents a node in a graph with a unique identifier, optional data, and a position in space.
 * @template T The type of data stored in this node.
 * @augments {Node<T>}
 */
class PositionNode<T> extends Node<T> {
  pos: Vector;

  public function new(data: T, pos: Vector) {
    super(data);
    this.pos = pos;
  }
}

class GraphUUId {
  static rng: Random = new Random();

  static generateUUID(): G_UUID {
    final uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';

    final generatedUuid = uuid.replace(/[xy]/g, function (c) {
      final r = (GraphUUId.rng.next() * 16) | 0;
      final v = c === 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });

    // Type assertion to convert string to branded type
    return generatedUuid as G_UUID;
  }
}
