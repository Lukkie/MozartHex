
/** First step: Check if move broke any disjoint sets with safe connections TODO**/
% For each set in CurrentDisjointSetsWithSafeConnections
    % Generate new disjoint sets




/** Second step: Check if move creates new disjoint sets with safe connections */
proc {GenerateDisjointSetsWithSafeConnections CurrentDisjointSetsWithSafeConnections Move TwoDList RelatedDisjointSets UnrelatedDisjointSets DisjointSetsWithSafeConnections}
  % Links disjointsets through their safe connections
  % Initialize RelatedDisjointSets to Move|nil
  case CurrentDisjointSetsWithSafeConnections of Set|Sr then
    local InSet in
      {MoveIsSafelyConnectedToSet Move SafelyConnectedSet InSet}
      if InSet then
        % If so, append Set to CurrentMoveSet
        {GenerateDisjointSetsWithSafeConnections Sr Move TwoDList {List.flatten Set|RelatedDisjointSets} UnrelatedDisjointSets DisjointSetsWithSafeConnections}
      else
        % If not, add Set to UnmodifiedSets
        {GenerateDisjointSetsWithSafeConnections Sr Move TwoDList RelatedDisjointSets Set|UnrelatedDisjointSets DisjointSetsWithSafeConnections}
      end
    end
  [] nil then
    DisjointSetsWithSafeConnections = RelatedDisjointSets | UnrelatedDisjointSets
  end
end

proc {MoveIsSafelyConnectedToSet Move Set TwoDList InSet}
  case Set of SetMove | Sr then
    % Check if move and setmove are safely connected
    % If so: Inset = true
    % Else: {MoveIsSafelyConnectedToSet Move Sr TwoDList InSet}
    local MovesConnected in
      MovesConnected = {MoveIsSafelyConnectedToMove Move SetMove TwoDList}
      if MovesConnected then InSet = true
      else {MoveIsSafelyConnectedToSet Move Sr TwoDList InSet}
      end
    end
  [] nil then
    InSet = false
  end
end

fun {MoveIsSafelyConnectedToMove Move SetMove TwoDList}
  if safely_connected then true
  else false end
end

/** TODO Wat als de andere speler er voor zorgt dat 2 originele safelyconnectedsets niet meer safely connected zijn??**/

/**
  Lijst van referenties naar DisjointSets
  safeconnection(DisjointSet1: _  DisjointSet2: _   X1:_ Y1:_ X2:_ Y2:_ )
  Opletten dat er geen duplicates tussen zitten (X1 en X2 gespiegeld)
  

**/
