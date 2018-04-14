functor
import
  Application(exit:Exit getArgs:GetArgs)
  System
  OS
  Browser(browse:Browse)
define
  Args = {GetArgs record('search_depth'(single type:int)
                                 'board_size'(single type:int))}

  if {Value.hasFeature Args 'search_depth'} then
    {Browse Args.search_depth}
  else
    {Browse 'No search_depth'}
  end

  if {Value.hasFeature Args 'board_size'} then
    {Browse Args.board_size}
  else
    {Browse 'No board_size'}
  end


  /* { Application.exit 0 } */

end
