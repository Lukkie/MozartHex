/**
  TODO: Safely connected
  TODO: Although we assume the opponent will always play in such way that it will stop your victories
          it will not always do this. Maybe don't assume a perfect opponent.
  TODO: Initialize with a great starting position
  TODO: Optimize for larger search depth
*/

functor
import
  Application(exit:Exit getArgs:GetArgs)
  System
  OS
  Browser(browse:Browse)
  Referee at 'referee.ozf'
  Player at 'player.ozf'
define
/** 11 by 11 board
                      RED
     (x, y):    (0,0) (1,0) (2,0) ...
              BLUE (0,1) (1,1) (2,1) ...
                      (0,2) (1,2) (2,2) ...
                         ...   ...   ...
    Blue direction: X
    Red direction: Y

**/
  DEFAULT_BOARD_SIZE = 11
  BLUE_TAG = 'Blu'
  RED_TAG = 'Red'
  DEFAULT_SEARCH_DEPTH = 3

/** Random seed used for testing against random opponent, not in actual implementation **/
  local Seed in
    Seed = {OS.rand} mod 50
    {System.showInfo 'Seed: ' # Seed}
    {OS.srand Seed}
  end
  /* {OS.srand 41} */


  local BOARD_SIZE SEARCH_DEPTH DEBUG RANDOM_OPPONENT in

    Args = {GetArgs record('search_depth'(single type:int)
                           'board_size'(single type:int)
                           'debug'(single)
                           'random_opponent'(single)
                            )}

    if {Value.hasFeature Args 'search_depth'} then
      SEARCH_DEPTH = Args.search_depth
    else
      SEARCH_DEPTH = DEFAULT_SEARCH_DEPTH
    end

    if {Value.hasFeature Args 'board_size'} then
      BOARD_SIZE = Args.board_size
    else
      BOARD_SIZE = DEFAULT_BOARD_SIZE
    end

    if {Value.hasFeature Args 'debug'} then
      DEBUG = true
    else
      DEBUG = false
    end

    if {Value.hasFeature Args 'random_opponent'} then
      RANDOM_OPPONENT = true
    else
      RANDOM_OPPONENT = false
    end

    /** Main thread **/

    fun {GetOtherColor Color}
      if Color == BLUE_TAG then RED_TAG
      else BLUE_TAG end
    end

    local Player1 Player2 RefereeThread in
      Player1 = {Player.player} % Get this from functor
      if RANDOM_OPPONENT then
        % For tests against random opponent
        Player2 = {Player.randomPlayer} % Get this from functor
      else
        Player2 = {Player.player} % Get this from functor
      end
      /* Player1 = {Player.randomPlayer} % Get this from functor */

      % Assume Referee is also a thread
      RefereeThread = {Referee.referee Player1 Player2} % Get this from functor


      local FinalBoard Winner Swapped in
        {Send RefereeThread startGame(FinalBoard Winner Swapped)} % Could also assign players here.

        if Swapped then
          {System.showInfo 'Winner is ' # Winner # ' after having swapped. Starting color was ' # {GetOtherColor Winner}}
        else
          {System.showInfo 'Winner is ' # Winner # ' which was also his original color'}
        end
      end
    end

  end % End of local variables SEARCH_DEPTH and BOARD_SIZE

  {Delay 500}
  { Exit 0 }

end
