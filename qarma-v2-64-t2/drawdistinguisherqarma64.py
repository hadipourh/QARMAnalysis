"""
MIT License

Copyright (c) 2023 Hosein Hadipour

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Email: hsn.hadipour@gmail.com
"""


import sys

def trim(docstring):
    if not docstring:
        return ''
    # Convert tabs to spaces (following the normal Python rules)
    # and split into a list of lines:
    lines = docstring.expandtabs().splitlines()
    # Determine minimum indentation (first line doesn't count):
    indent = sys.maxsize
    for line in lines[1:]:
        stripped = line.lstrip()
        if stripped:
            indent = min(indent, len(line) - len(stripped))
    # Remove indentation (first line is special):
    trimmed = [lines[0].strip()]
    if indent < sys.maxsize:
        for line in lines[1:]:
            trimmed.append(line[indent:].rstrip())
    # Strip off trailing and leading blank lines:
    while trimmed and not trimmed[-1]:
        trimmed.pop()
    while trimmed and not trimmed[0]:
        trimmed.pop(0)
    # Return a single string:
    return '\n'.join(trimmed)

class Draw():
    """
    Draw the shape of ID attack
    """

    def __init__(self, integral_object, output_file_name="output.tex", attack_summary=""):
        self.result = integral_object.result
        self.RU = integral_object.RU
        self.RL = integral_object.RL
        self.RD = self.RU + self.RL        
        self.attack_summary = attack_summary        
        self.inv_permutation = [0, 5, 15, 10, 13, 8, 2, 7, 11, 14, 4, 1, 6, 3, 9, 12]                                  
        self.output_file_name = output_file_name
        self.fillcolor = {0: "white", 1: "nonzerofixed", 2: "nonzeroany", 3: "unknown"}
        self.lazy_tweak_cells_numeric = integral_object.lazy_tweak_cells_numeric
        self.lazy_tweak_cells_numeric_zero = integral_object.lazy_tweak_cells_numeric_zero
        self.lazy_tweak_cells_numeric_one = integral_object.lazy_tweak_cells_numeric_one

    def gen_round_tweakey_labels(self, round_number):
        """
        Generate the round tweakey labels
        """
        
        round_tweakey_state = self.result["tk_permutation_per_round"][round_number]          
        text = ""
        for i in range(16):
            text += "\Cell{{s{0}}}{{\\texttt{{{1}}}}}".format(i, hex(round_tweakey_state[i])[2:])
        return text
    
    def draw_eu(self, r):
        """
        Paint EU
        """
        
        output = dict()
        output["before_sb"] = ""              
        output["after_sb"] = ""
        output["after_addtk"] = ""
        output["after_pr"] = ""
        output["subtweakey"] = ""
        output["after_mix_columns"] = ""
        tk_permutation_per_round = self.result["tk_permutation_per_round"][r]              
        for i in range(16):
            output["before_sb"] += "\Fill[{0}]{{s{1}}}".format(self.fillcolor[self.result["forward_mask_x"][r][i]], i)
            output["after_sb"] += "\Fill[{0}]{{s{1}}}".format(self.fillcolor[self.result["forward_mask_sbx"][r][i]], i)
            output["after_addtk"] += "\Fill[{0}]{{s{1}}}".format(self.fillcolor[self.result["forward_mask_sbx"][r][i]], i)                
            output["after_pr"] += "\Fill[{0}]{{s{1}}}".format(self.fillcolor[self.result["forward_mask_sbx"][r][i]], self.inv_permutation[i])
            output["after_mix_columns"] += "\Fill[{0}]{{s{1}}}".format(self.fillcolor[self.result["forward_mask_x"][r + 1][i]], i)               
        for i in range(16):                        
            output["subtweakey"] += "\Fill[{0}]{{s{1}}}".format(self.fillcolor[self.result["forward_mask_sbx"][r][i]], i)
        for j in range(16):
            if r%2 == 0:
                if tk_permutation_per_round[j] in self.lazy_tweak_cells_numeric_zero:
                    output["subtweakey"] += "\FrameCell[filter]{{s{0}}}".format(j)
            else:
                if tk_permutation_per_round[j] in self.lazy_tweak_cells_numeric_one:
                    output["subtweakey"] += "\FrameCell[filter]{{s{0}}}".format(j)
        return output

    def draw_el(self, r):
        """
        Paint EL
        """
        
        output = dict()
        output["before_sinv"] = ""
        output["after_sinv"] = ""              
        output["after_minv"] = ""
        output["after_prinv"] = ""
        output["subtweakey"] = ""
        tk_permutation_per_round = self.result["tk_permutation_per_round"][self.RU + r]
        for i in range(16):            
            output["after_minv"] += "\TFill[{0}]{{s{1}}}".format(self.fillcolor[self.result["backward_mask_sbx"][self.RL - r - 1][0][i]], self.inv_permutation[i]) 
            output["after_prinv"] += "\TFill[{0}]{{s{1}}}".format(self.fillcolor[self.result["backward_mask_sbx"][self.RL - r - 1][0][i]], i)
            output["before_sinv"] += "\TFill[{0}]{{s{1}}}".format(self.fillcolor[self.result["backward_mask_sbx"][self.RL - r - 1][0][i]], i)
            output["after_sinv"] += "\TFill[{0}]{{s{1}}}".format(self.fillcolor[self.result["backward_mask_x"][self.RL - r - 1][0][i]], i)               
        for i in range(16):
            output["subtweakey"] += "\TFill[{0}]{{s{1}}}".format(self.fillcolor[self.result["backward_mask_sbx"][self.RL - r - 1][0][i]], i)

        for i in range(16):            
            output["after_minv"] += "\BFill[{0}]{{s{1}}}".format(self.fillcolor[self.result["backward_mask_sbx"][self.RL - r - 1][1][i]], self.inv_permutation[i]) 
            output["after_prinv"] += "\BFill[{0}]{{s{1}}}".format(self.fillcolor[self.result["backward_mask_sbx"][self.RL - r - 1][1][i]], i)
            output["before_sinv"] += "\BFill[{0}]{{s{1}}}".format(self.fillcolor[self.result["backward_mask_sbx"][self.RL - r - 1][1][i]], i)
            output["after_sinv"] += "\BFill[{0}]{{s{1}}}".format(self.fillcolor[self.result["backward_mask_x"][self.RL - r - 1][1][i]], i)               
        for i in range(16):
            output["subtweakey"] += "\BFill[{0}]{{s{1}}}".format(self.fillcolor[self.result["backward_mask_sbx"][self.RL - r - 1][1][i]], i)
           
        for j in range(16):
            if (self.RU + r)%2 == 0:
                if tk_permutation_per_round[j] in self.lazy_tweak_cells_numeric_zero:
                    output["subtweakey"] += "\FrameCell[filter]{{s{0}}}".format(j)
            else:
                if tk_permutation_per_round[j] in self.lazy_tweak_cells_numeric_one:
                    output["subtweakey"] += "\FrameCell[filter]{{s{0}}}".format(j)
        return output
    
    def generate_attack_shape(self):
        """
        Draw the figure of the Rectangle distinguisher
        """

        contents = ""
        initial_state = ""
        for i in range(16):
            initial_state += "\Fill[{0}]{{s{1}}}".format(self.fillcolor[self.result["forward_mask_x"][0][i]], i)
        # head lines
        contents += trim(r"""
                    \documentclass[varwidth=50cm]{standalone}
                    \usepackage{qarmavtwo64}
                    \usepackage{comment}
                    \begin{document}
                    %\begin{figure}
                    %\centering
                    \begin{tikzpicture}
                    \QarmaInit{""" + initial_state + r"""} % init coordinates, print labels""") + "\n\n"
        # draw EU
        for r in range(0, self.RU):
            state = self.draw_eu(r)
            state["subtweakey"] += self.gen_round_tweakey_labels(r)
            if r < self.RU - 1:
                contents += trim(r"""
                \QarmaForwardNewLine
                    {$S$} % first operation name (S or \tau')
                    {""" + state["after_sb"] + r"""} % state after first operation (S)
                    {""" + state["subtweakey"] + r"""} % tweakey state
                    {""" + state["after_addtk"] + r"""} % state after tweakey addition
                    {$\tau$} % second operation name (\tau or S')
                    {""" + state["after_pr"] + r"""} % state after second operation (\tau)
                    {$M$} % third operation name (M or M')
                    {""" + state["after_mix_columns"] + r"""} % state after third operation (M)""") + "\n\n"

            elif r == (self.RU - 1):
                output_state = ""
                for i in range(16):
                    output_state += "\TFill[{0}]{{s{1}}}".format(self.fillcolor[self.result["backward_mask_x"][self.RL][0][i]], i)        
                    output_state += "\BFill[{0}]{{s{1}}}".format(self.fillcolor[self.result["backward_mask_x"][self.RL][1][i]], i)
                contents += trim(r"""
                \QarmaForwardFinal               
                    {$S$} % first operation name (S or \tau')
                    {""" + state["after_sb"] + r"""} % state after first operation (S)
                    {""" + state["subtweakey"] + r"""} % tweakey state
                    {""" + state["after_addtk"] + r"""} % state after tweakey addition
                    {$\tau$} % second operation name (\tau or S')
                    {""" + state["after_pr"] + r"""} % state after second operation (\tau)
                    {$M$} % third operation name (M or M')
                    {""" + state["after_mix_columns"] + r"""} % state after third operation (M)""") + "\n\n"
                            
        # draw EL
        for r in range(0, self.RL):
            state = self.draw_el(r)
            state["subtweakey"] += self.gen_round_tweakey_labels(self.RU + r)            
            contents += trim(r"""
                        \QarmaBackwardNewLine              
                            {$\bar{M}$} % M^-1
                            {""" + state["after_minv"] + r"""} % state after M^-1
                            {$\bar{\tau}$} % tau inverse
                            {""" + state["after_prinv"] + r"""} % state after tau inverse
                            {""" + state["subtweakey"] + r"""} % tweakey state
                            {""" + state["before_sinv"] + r"""} % state before sinverse
                            {$\bar{S}$} % S^-1
                            {""" + state["after_sinv"] + r"""} % state after S^-1""") + "\n\n"

            
        contents += r"""%\IntegralDistinguisherLegend""" + "\n"
        contents += r"""\end{tikzpicture}""" + "\n"
        contents += r"""%\caption{Integral distinguisher for """ +  str(self.RD + 2) +\
                    r""" rounds of QARMA-v2-64""" + "}\n"
        contents += trim(r"""%\end{figure}""") + "\n"
        contents += trim(r"""\begin{comment}""") + "\n"
        contents += self.attack_summary
        contents += trim(r"""\end{comment}""") + "\n"
        contents += trim(r"""\end{document}""")
        with open(self.output_file_name, "w") as output_file:
            output_file.write(contents)
