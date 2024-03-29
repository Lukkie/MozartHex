functor
import
  Application(getArgs:GetArgs)
  System
  OS
  /* Browser(browse:Browse) */
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
  DEFAULT_SEARCH_DEPTH = 3

/** Random seed only used for testing against random opponent, not in actual player implementation **/
  local Seed in
    Seed = {OS.rand} mod 50
    {System.showInfo 'Seed: ' # Seed}
    {OS.srand Seed}
  end


  local BOARD_SIZE SEARCH_DEPTH DEBUG RANDOM_OPPONENT in

    Args = {GetArgs record('search_depth'(single type:int)
                           'board_size'(single type:int)
                           'debug'(single)
                           'random_opponent'(single)
                           'swap'(single type:int)
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

    local Player1 Player2 RefereeThread in
      Player1 = {Player.player} % Get this from functor
      if RANDOM_OPPONENT then
        % For tests against random opponent
        Player2 = {Player.randomPlayer} % Get this from functor
      else
        Player2 = {Player.player} % Get this from functor
      end

      % Assume Referee is also a thread
      RefereeThread = {Referee.referee Player1 Player2} % Get this from functor


      {Send RefereeThread startGame()} % Could also assign players here.

    end
  end % End of local variables SEARCH_DEPTH and BOARD_SIZE

end
