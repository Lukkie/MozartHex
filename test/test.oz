functor
import
  Application(exit:Exit)
  System
  /* QTk at 'x-oz://system/wp/QTk.ozf' */
define
  {System.showInfo 'Hello World!'}
  {Time.delay 5000}
  {System.showInfo 'Hello World once again!'}
  { Exit 0 }

end
