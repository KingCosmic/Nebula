package nebula.entitycomponentsystem;

/**
 * Higher priorities run earlier than others in the system update
 */
final SystemPriority = {
  Highest: -Infinity,
  Higher: -5,
  Average: 0,
  Lower: 5,
  Lowest: Infinity
};
