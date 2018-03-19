% 11 by 11 board
functor
import
  Application(exit:Exit)
  System
  /* Browser(browse:Browse) */
  /* Array */

define
  BOARD_SIZE = 3

  local
     fun {Loop From To}
        if From > To
        then nil
        else From | {Loop From+1 To}
        end
     end

     proc {IterateOverItems Array} % Without explicit indexing... Maybe a different array structure exists to allow explicit index (e.g. Array.4)
        case Array of X|Xs then
          {System.showInfo X}
          {IterateOverItems Xs}
        [] nil then skip end
     end
  in
     {System.showInfo '--------------------'}
     {System.showInfo 'Using recursive calls (part 1):'}
     {IterateOverItems {Loop 0 10}} % Displays: [0,1,2,3,4,5,6,7,8,9,10]
  end

  {System.showInfo '--------------------'}
  {System.showInfo 'Using recursive calls (part 2):'}

  % HOW TO MAKE MULTI-DIMENSIONAL ARRAY ??
  local
     fun {Loop From To}
        if From > To
        then nil
        else 'test'  | {Loop From+1 To}
        end
     end

     proc {IterateOverItems Array} % Without explicit indexing... Maybe a different array structure exists to allow explicit index (e.g. Array.4)
        case Array of X|Xs then
          {System.showInfo X}
          {IterateOverItems Xs}
        [] nil then skip end
     end
  in
     {IterateOverItems {Loop 0 10}} % Displays: [0,1,2,3,4,5,6,7,8,9,10]
  end

  {System.showInfo '--------------------'}
  {System.showInfo 'Using List module for 1 to 10 (atoms) list:'}

  Lijst = {List.number 1 10 1}
  for Item in Lijst do
    {System.showInfo Item}
  end


  {System.showInfo '--------------------'}
  {System.showInfo 'Using List module to generate nested lists:'}

  /* Lijst = { NewArray 1 10 'test' } */

  NestedList = {List.make BOARD_SIZE} % Variables instead of atoms
  for Item in NestedList do
    Item = { List.make BOARD_SIZE }
    for NestedItem in Item do
      NestedItem = 'emptyy'
    end
  end

  /* { List.nth { List.nth NestedList 2 } 2 } = 'NUMBER TWO' */  % DOES NOT WORK

  for Item in NestedList do
    for NestedItem in Item do
      {System.showInfo NestedItem}
    end
  end


  {System.showInfo '--------------------'}
  {System.showInfo 'Using Array module to generate nested arrays:'}
  % Works to create, but how do you display it nicely? I.e. a 11x11 matrix.
  OutputString = {Cell.new ''}
  NestedArray = {Array.new 1 BOARD_SIZE {Atom.toString 'test'} }
  /* {Array.put NestedArray 4 'Position 5'} */
  for I in 1..BOARD_SIZE do
    {Array.put NestedArray I {Array.new 1 BOARD_SIZE 'empty'}}
    for J in 1..BOARD_SIZE do
      OutputString := @OutputString # {Array.get {Array.get NestedArray I} J} # '\t'
      /* {List.append OutputString {Array.get {Array.get NestedArray I} J} OutputString }
      {List.append OutputString {Atom.toString '\t'} OutputString} */
      /* {System.showInfo {Array.get {Array.get NestedArray I} J}} */
    end
    OutputString := @OutputString # '\n'
  end
  {System.showInfo @OutputString}


  /* {Time.delay 5000} */
  { Exit 0 }

end
