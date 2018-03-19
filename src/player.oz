functor
import
  Application(exit:Exit)
  System

export
  generateMove:GenerateMove
  startPlayer:StartPlayer

define
  % Generates a move on current board using the assigned color and returns x and y of the move
  proc {GenerateMove Board Color ?X ?Y}
    X = 5
    Y = 10
  end

  proc {StartPlayer SharedPort Color}
    {System.showInfo SharedPort}
  end

end
