% 11 by 11 board
functor
import
  Application(exit:Exit)
  System
  /* Browser(browse:Browse) */
  /* Array */

define
  BOARD_SIZE = 11

  proc {DisplayBoard Board}
    local OutputString in
      OutputString = {Cell.new ''}
      for I in 1..BOARD_SIZE do
        for J in 1..BOARD_SIZE do
          OutputString := @OutputString # {Array.get {Array.get NestedArray I} J} # '\t'
        end
        OutputString := @OutputString # '\n'
      end
      {System.showInfo @OutputString}
    end
  end

  % Create Board
  NestedArray = {Array.new 1 BOARD_SIZE {Atom.toString 'test'} }
  /* {Array.put NestedArray 4 'Position 5'} */
  for I in 1..BOARD_SIZE do
    {Array.put NestedArray I {Array.new 1 BOARD_SIZE 'empty'}}
  end
  {DisplayBoard NestedArray}

  % Create Players

  % Start game Loop

      % Ask player for move

      % Check correctness

      % Return an answer to the player


  { Exit 0 }

end
