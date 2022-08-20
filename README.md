# the_younger_me

This is a practising project for the Special Relativity and js and ocaml.

What it does is basically based on the Twin Paradox. It is a simulator of the Special Relativity using purly Lorentz Transformation which I cite here.

$$
\begin{bmatrix}
\gamma & -\gamma{v_x \over c^2} & -\gamma{v_y \over c^2}\\
-\gamma{v_x \over c^2} & 1+(\gamma-1){v_x^2\over v^2} & (\gamma-1){v_xv_y\over v^2}\\
-\gamma{v_y \over c^2} & (\gamma-1){v_xv_y\over v^2} & 1+(\gamma-1){v_x^2\over v^2}\\
\end{bmatrix}
$$

$\gamma = {1\over \sqrt{1-{v^2\over c^2}}}$

How to play:

1. Click to add an amount of velocity to a certain direction (there's a limit for not depassing the speed of light).
2. There's two numbers indicating at the upper-left corner of screen, respectively the time indicated by a clock on earth and the time indicated by a clock on the ship, in a Galilean referential which is of the same velocity as the ship to the earth.
