% 11 by 11 board
functor
import
  Application(exit:Exit)
  System
  Browser(browse:Browse)

define

  Tree = tree(tree(tree(node(4) node(6)) tree(node(7) node(9))) tree(tree(node(1) node(2)) tree(node(0) node(1))))
  /* {Browse Tree} */

  proc {MaximizePlayer Tree Depth Alpha Beta CurrentV ?V}
    if Depth == 0 then
      % calculate score
      case Tree of node(Score) then
        V = Score
      end

    else
      local NewV, MaxV, NewAlpha in
        {MinimizePlayer()}

      end
    end


  end

  /* { Exit 0 } */

end
