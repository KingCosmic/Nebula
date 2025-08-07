package nebula.math;

import nebula.math.Random;
import nebula.math.Vector;

interface EdgeOptions {
  var weight: Int;
  var useEuclidean: Null<false>;
  /**
   * Whether the edge is directed.
   * @default false
   */
  var directed: Null<Bool>;
}

/**
 * A weighted graph data structure.
 * @template T The type of data stored in each node.
 */
class Graph<T> {
  private var _nodes: Map<String, Node<T>>;
  private var _edges: Map<Edge<T>, Bool>;
  var adjacencyList: Map<String, Map<String, Bool>>;
  var id: String = GraphUUId.generateUUID();

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
  function addNode(data: T): Node<T> {
    var newNode = new Node(data);
    this._nodes.set(newNode.id, newNode);
    this.adjacencyList.set(newNode.id, new Set());
    return newNode;
  }

  function addPositionNode(data: T, position: Vector): PositionNode<T> {
    var newNode = new PositionNode(data, position);
    this._nodes.set(newNode.id, newNode);
    this.adjacencyList.set(newNode.id, new Set());
    return newNode;
  }

  /**
   * Adds multiple new nodes to the graph with the given data.
   * @returns A map of all nodes in the graph, including the newly created ones.
   */
  function addNodes(nodes: Array<T>): Map<String, Node<T>> {
    for (node in nodes) {
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
  function deleteNode(node: Node<T>): Map<String, Node<T>> {
    //delete any edges tied to node
    final nodeEdges = node.edges;
    for (edge in nodeEdges) {
      this.deleteEdge(edge);
    }

    this.adjacencyList.forEach((value, key) -> {
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

  function addEdge(from: Node<T>, to: Node<T>, options?: EdgeOptions): Array<Edge<T>> {
    //gaurd clauses
    final existingEdges = Array.from(this._edges).find((edge) -> edge.source.id == from.id && edge.target.id == to.id);
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

  function deleteEdge(edge: Edge<T>) {
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
  public var nodes(get, never): Map<String, Node<T>>;
  function get_nodes(): Map<String, Node<T>> {
    return this._nodes;
  }

  /**
   * Gets a node by its UUID.
   * @param id - The UUID of the node to be retrieved.
   * @returns The node with the specified UUID, or undefined if no such node exists.
   */
  function getNode(id: String): Node<T> {
    return this._nodes.get(id)!;
  }

  /**
   * Retrieves the set of edges in the graph.
   *
   * The returned set is a shallow copy of the internal edge set.
   * Modifications to this set do not affect the graph's internal state.
   * @returns A set containing all edges in the graph.
   */
  public var edges(get, never): Map<Edge<T>, Bool>;
  function get_edges(): Map<Edge<T>, Bool> {
    return this._edges;
  }

  /**
   * Gets the neighbors of the given node.
   *
   * The returned array contains all of the nodes that are directly connected to the given node.
   * @param node - The node whose neighbors should be retrieved.
   * @returns An array of nodes that are directly connected to the given node.
   */
  function getNeighbors(node: Node<T>): Array<Node<T>> {
    return Array.from(this.adjacencyList.get(node.id) ?? []).map((nid) -> this.nodes.get(nid)!);
  }

  /**
   * Checks if two nodes are connected by an edge.
   * @param node1 - The first node to check.
   * @param node2 - The second node to check.
   * @returns true if the nodes are connected, false if not.
   */
  function areNodesConnected(node1: Node<T>, node2: Node<T>): Bool {
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
  function bfs(startNode: Node<T>): Array<String> {
    // Verify the start node exists in the graph
    if (!this._nodes.has(startNode.id)) {
      return [];
    }

    final queue: Array<String> = [startNode.id];
    final visited: Map<String, Bool> = new Map([startNode.id]);

    while (queue.length > 0) {
      final nodeId = queue.shift()!;
      final neighbors = this.adjacencyList.get(nodeId) || new Set();
      for (neighborId in neighbors) {
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
  function dfs(startNode: Node<T>, visited: Map<String, Bool> = new Map()): Array<String> {
    final startId: String = startNode.id;
    if (!this._nodes.has(startId)) {
      return [];
    } // Invalid start node

    visited.add(startId);
    var result: Array<String> = [startId];

    for (neighbor in this.adjacencyList.get(startId) ?? []) {
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
  static function createGraphFromNodes<T>(nodes: Array<T>): Graph<T> {
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

  function dijkstra(sourcenode: Node<T>): Array<{ node: Node<T>; distance: Int; previous: Null<Node<T>> }> {
    final visited: Array<Node<T>> = [];
    final unvisited: Array<Node<T>> = [];
    final resultArray: Array<{ node: Node<T>; distance: Int; previous: Null<Node<T>> }> = [];

    //fill unvisited
    this.nodes.forEach((node) -> unvisited.push(node));

    //fill resultArray
    this.nodes.forEach((node) -> resultArray.push({ node, distance: Infinity, previous: null }));

    //start with starting node
    //add startingnode to result array
    final startingNodeIndex = resultArray.findIndex((node) -> node.node === sourcenode);
    if (startingNodeIndex == -1) {
      return [];
    }
    resultArray[startingNodeIndex].distance = 0;

    visited.push(sourcenode);
    unvisited.splice(unvisited.indexOf(sourcenode), 1);

    var current = sourcenode;
    final currentEdges = current.edges;
    final filteredCurrentEdges: Array<Edge<T>> = Array.from(currentEdges).filter((edge: Edge<T>) -> edge.target != current);

    //update result array with distances, which is edge values

    for (edge in filteredCurrentEdges) {
      final index = resultArray.findIndex((node) -> node.node == edge.target);

      if (index == -1) {
        return [];
      }
      resultArray[index].distance = edge.weight;
      resultArray[index].previous = current;
    }

    while (unvisited.length > 0) {
      //get list of unvisited available nodes
      var listOfAvailableNodes: Array<Node<T>> = [];
      var listofAvailableEntries: Array<{ node: Node<T>; distance: Int; previous: Null<Node<T>> }> = [];
      listofAvailableEntries = resultArray.filter((node) -> unvisited.includes(node.node));
      listOfAvailableNodes = listofAvailableEntries.map((node) -> node.node);

      //loop through available nodes and find lowest distance to sourcenode
      var lowestDistance = Infinity;
      var lowestDistanceIndex = -1;

      if (listOfAvailableNodes.length > 0) {
        for (var i = 0; i < listOfAvailableNodes.length; i++) {
          final unVisitiedNode = listOfAvailableNodes[i];

          final index = resultArray.findIndex((node) -> node.node == unVisitiedNode);
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
          final index = resultArray.findIndex((node) -> node.node == unVisitiedNode);
          if (resultArray[index].distance < lowestDistance) {
            lowestDistance = resultArray[index].distance;
            lowestDistanceIndex = index;
          }
        }
      }

      if (lowestDistanceIndex == -1) {
        return [];
      }

      current = resultArray[lowestDistanceIndex].node;
      var currentEdgesArray = Array.from(current.edges);

      //remove visited from currentEdges
      currentEdgesArray = currentEdgesArray.filter((edge: Edge<T>) -> {
        return !visited.includes(edge.source) && !visited.includes(edge.target) && edge.target != current;
      });

      visited.push(current);
      unvisited.splice(unvisited.indexOf(current), 1);

      //update result array with distances, which is edge values
      for (var i = 0; i < currentEdgesArray.length; i++) {
        final edge = currentEdgesArray[i];
        final index = resultArray.findIndex((node) -> node.node == edge.target);

        //update cumulative distances
        final previousIndex = resultArray.findIndex((node) -> node.node == edge.source);

        final previousDistance = resultArray[previousIndex].distance;
        final cumDistance = (previousDistance + edge.weight!);

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
  function shortestPathDijkstra(startingNode: Node<T>, endNode: Node<T>): { path: Array<Node<T>>; distance: Int } {
    final dAnalysis = this.dijkstra(startingNode);

    if (dAnalysis.length == 0) {
      return { path: [], distance: Infinity };
    }
    //iterate through dAnalysis to plot shortest path to endnode
    final path: Array<Node<T>> = [];
    var current: Null<Node<T>> = endNode;
    final distance = dAnalysis.find((node) -> node.node == endNode)?.distance;

    while (current != null) {
      path.push(current);

      current = dAnalysis.find((node) -> node.node == current)?.previous;

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
  function aStar(
    startNode: PositionNode<T>,
    endNode: PositionNode<T>
  ): {
    path: Null<Array<PositionNode<T>>>;
    pathSteps: Int;
    distance: Int;
    skippedNodes: Map<String, Bool>;
  } {
    // Make sure we're working with PositionNodes
    if (!('pos' in startNode) || !('pos' in endNode)) {
      throw new Error('A* algorithm requires PositionNode with position vectors');
    }

    // Initialize data structures
    final openSet: Map<String, Bool> = new Map([startNode.id]);
    final closedSet: Map<String, Bool> = new Map();
    final skippedNodes: Map<String, Bool> = new Map();

    // Track g scores (distance from start) and f scores (estimated total cost)
    final gScore: Map<String, Int> = new Map();
    final hScore: Map<String, Int> = new Map();
    final fScore: Map<String, Int> = new Map();

    // Track the path
    final cameFrom: Map<String, Null<String>> = new Map();

    // Initialize scores

    //remap positionNodes from this._nodes where node is type of PositionNode
    final positionNodes: Map<String, PositionNode<T>> = new Map();
    for (nodeId => node in this._nodes) {
      if ('pos' in node) {
        positionNodes.set(nodeId, node as PositionNode<T>);
      } else {
        skippedNodes.add(nodeId);
      }
    }

    for (nodeId => _ in positionNodes) {
      gScore.set(nodeId, this._euclideanDistance(positionNodes.get(nodeId)!, startNode));
      hScore.set(nodeId, this._euclideanDistance(positionNodes.get(nodeId)!, endNode));
      fScore.set(nodeId, gScore.get(nodeId)! + hScore.get(nodeId)!);
      cameFrom.set(nodeId, null);
    }

    // Continue until we've visited all nodes or found the target
    while (openSet.size > 0) {
      // Find node with lowest fScore
      var currentId: Null<String> = null;
      var lowestFScore = Infinity;

      for (nodeId in openSet) {
        final score = fScore.get(nodeId) || Infinity;
        if (score < lowestFScore) {
          lowestFScore = score;
          currentId = nodeId;
        }
      }

      // If we can't find a node, there's no path
      if (currentId == null) {
        break;
      }

      // If we found the target, we're done
      if (currentId == endNode.id) {
        // Reconstruct path
        final path: Array<PositionNode<T>> = [];
        var current: Null<String> = endNode.id;

        while (current != null) {
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
      final currentNode = this._nodes.get(currentId)!;

      // Check all neighbors
      final neighbors = this.getNeighbors(currentNode);

      for (neighbor in neighbors) {
        final neighborId = neighbor.id;

        // Skip if neighbor has been processed
        if (closedSet.has(neighborId)) {
          continue;
        }

        // Ensure neighbor is a PositionNode
        final positionNeighbor = neighbor;
        if (!('pos' in positionNeighbor)) {
          continue;
        }

        // Find the edge connecting current to neighbor
        final edge: Edge<T> = Array.from(currentNode.edges).find((e: Edge<T>) -> e.source.id == currentId && e.target.id == neighborId);

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

  private function _euclideanDistance(currentNode: PositionNode<T>, testNode: PositionNode<T>): Float {
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
  private var _id: String = GraphUUId.generateUUID();
  private var _source: Node<T>;
  private var _target: Node<T>;
  private var _weight: Int = 0;
  private var _partnerEdge: Null<Edge<T>> = null; // Reference to the opposite direction edge

  public function new(source: Node<T>, target: Node<T>, ?config: EdgeOptions) {
    this._source = source;
    this._target = target;
    if (config && config.weight) {
      this._weight = config.weight;
    } else if (config && config.useEuclidean) {
      this._weight = source.pos.distance(target.pos); //calc weight
    } else {
      this._weight = 0;
    }
  }

  function linkWithPartner(partnerEdge: Edge<T>): Void {
    this._partnerEdge = partnerEdge;
  }

  public var id(get, never): String;
  function get_id() {
    return this._id;
  }

  public var source(get, never): Node<T>;
  function get_source() {
    return this._source;
  }

  public var target(get, never): Node<T>;
  function get_target() {
    return this._target;
  }

  public var weight(get, never): Int;
  function get_weight() {
    return this._weight;
  }

  public var partnerEdge(get, never): Null<Edge<T>>;
  function get_partnerEdge() {
    return this._partnerEdge;
  }
}

/**
 * Represents a node in a graph, with a unique identifier and optional data.
 * @template T The type of data stored in this node.
 */
class Node<T> {
  private var _id: String = GraphUUId.generateUUID();
  private var _data: T;
  private var _edges: Map<Edge<T>, Bool>;

  public function new(data: T) {
    this._data = data;
    this._edges = new Set();
  }

  public var id(get, never): String;
  function get_id(): String {
    return this._id;
  }

  public var data(get, never): T;
  function get_data() {
    return this._data;
  }

  public var edges(get, never): Map<Edge<T>, Bool>;
  function get_edges() {
    return this._edges;
  }

  function registerNewEdge(newEdge: Edge<T>) {
    this._edges.add(newEdge);
  }

  function breakEdge(edge: Edge<T>) {
    this._edges.delete(edge);
  }

  function getConnectedNodes(): Array<Node<T>> {
    return Array.from(this._edges).map((edge) -> edge.target);
  }
}

/**
 * Represents a node in a graph with a unique identifier, optional data, and a position in space.
 * @template T The type of data stored in this node.
 * @augments {Node<T>}
 */
class PositionNode<T> extends Node<T> {
  var pos: Vector;

  public function new(data: T, pos: Vector) {
    super(data);
    this.pos = pos;
  }
}

class GraphUUId {
  static var rng: Random = new Random();

  static function generateUUID(): String {
    final uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';

    final generatedUuid = uuid.replace(~/[xy]/g, function (c) {
      final r = (GraphUUId.rng.next() * 16) | 0;
      final v = c === 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });

    // Type assertion to convert string to branded type
    return generatedUuid;
  }
}
