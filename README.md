# 287_final_project

**WHAT IT IS**
What we have created is a graphing calculator. It takes inputs for up to 8 coefficients via switches on the board. Once the desired inputs have been selected, the calculator will calculate the derivatives, 

**HOW IT WORKS**

INPUTS
The coefficients are entered in binary via a switches on the DE2 board.

First, a power of X, 0 – 7, is selected in binary using SW6 to SW4.
( SW6 , SW5 , SW4 )

Next, the desired value of the coefficient, 0-9, is entered in binary using SW3 to SW0.
( SW3 , SW2 , SW1 , SW0 )

The sign of the polynomial is then selected using SW9.
( HIGH for negative, LOW for positive ) 

Once the desired power of X, coefficient, and sign have all been entered in switches on the board, SW8 is flipped to update the value on the appropriate hex display and is then flipped back down. 

Once the desired value is entered on the hex display, SW7 is flipped to updated the value being used by the calculator, and updates what is displayed on the monitor.

OUTPUTS
******VGA******

The hardest part of the project was getting something meaningful to display using the VGA port.

The VGA outputs are pin assigned appropriately.

The top ~100 pixels of the display is the row of polynomials. 

The graph itself has a scale of +- 25 in each direction.

What it basically does is, it takes an input function, calculates the corresponding X value for the Y valued function, and then displays a dot at that point. 




******HEX******

The HEX displays show the current coefficient values that that calculator is currently using to create a graph.

Each HEX corresponds to its respective coefficient.
(HEX7 -> coef of x^(7) , HEX6 -> coef of x^(6) , etc.  )

*****LED_G*****

The Green_LEDs show the current sign of each coefficient that the calculator is currently using to create a graph.
( ON -> neg value , OFF -> pos value )

Each LED_G corresponds to its respective coefficient’s sign. 
( LED_G7 -> sign of x^(7) , LED_G6 -> sign of x^(6) , etc. )

**WHAT WAS EASY**
Inputs were probably the easiest part of the project. It’s quite easy to give something a value, but more difficult to do something useful with that value. Creating a module to 

That being said, the computation of the derivatives was also quite trivial, given merely simple polynomials with easy derivative rules. 

**WHAT WAS HARD**
Nearly every issue we have encountered in this project has had something to do with signal timing. The VGA has been the challenge. Getting it to work with minor drawings was simple with the help past project examples because the computations took hardly any time to complete inside the VGA module, but as soon as the drawings became extensive, we became forced to do the computations elsewhere. 

We ended up just controlling individual pixels on the monitor, since that is the simplest way of attacking the display, and what made the most sense to us. It will display the coefficients at the top of the screen, and the graph (the value of the function) at every ninth pixel. 

**WHAT WAS LEARNED**
VGA timing is crucial to the entire operation. Giving the VGA controller the RGB signal at the precise moment that it expects it, is the difference between displaying everything and displaying nothing at all. 

After watching many youtube videos, looking at tutorials, and asking around the class, we finally were able the modify a VGA module that we got from Barret Heaton and his lab partner. 

The module is the more basic (and better organized) than any we have tried to create and merely expects RGB signals for a specific pixel location. We were able to manipulate the color of the display on a pixel-by-pixel level

**HELP RECEIVED**
Barret Heaton and his lab partner helped us out a lot with the VGA. We in turn helped them with the finite state machine of their project with troubleshooting and counter. 


