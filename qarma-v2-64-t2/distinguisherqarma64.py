#!/usr/env/bin python3
#-*- coding: UTF-8 -*-

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

email: hsn.hadipour@gmail.com
"""

import time
import minizinc
import datetime
from argparse import ArgumentParser, RawTextHelpFormatter
from drawdistinguisherqarma64 import *
from pathlib import Path
line_separator = "#"*55

class IntegralDistinguisher:
    ID_counter = 0

    def __init__(self, params) -> None:
        IntegralDistinguisher.ID_counter += 1
        self.id = IntegralDistinguisher.ID_counter
        self.name = "IntegralDistinguisher" + str(self.id)
        self.type = "IntegralDistinguisher"

        self.RU = params["RU"] - 1
        self.RL = params["RL"] - 1
        self.KR = params["KR"]
        self.cp_solver_name = params["cp_solver_name"]
        self.time_limit = params["time_limit"]
        self.num_of_threads = params["num_of_threads"]
        self.output_file_name = params["output_file_name"]

        self.supported_cp_solvers = ['gecode', 'chuffed', 'cbc', 'gurobi',
                                     'picat', 'scip', 'choco', 'ortools']
        ##################################################
        # Use this block if you install Or-Tools bundeled with MiniZinc
        if self.cp_solver_name == "ortools":
            self.cp_solver_name = "com.google.ortools.sat"
        ################################################## 
        assert(self.cp_solver_name in self.supported_cp_solvers)
        self.cp_solver = minizinc.Solver.lookup(self.cp_solver_name)
        self.mzn_file_name = "distinguisherqarma64.mzn"
        self.NPT = 1        
                    
    #############################################################################################################################################
    #############################################################################################################################################
    #############################################################################################################################################
    #  ____          _               _    _             __  __             _        _ 
    # / ___|   ___  | |__   __ ___  | |_ | |__    ___  |  \/  |  ___    __| |  ___ | |
    # \___ \  / _ \ | |\ \ / // _ \ | __|| '_ \  / _ \ | |\/| | / _ \  / _` | / _ \| |
    #  ___) || (_) || | \ V /|  __/ | |_ | | | ||  __/ | |  | || (_) || (_| ||  __/| |
    # |____/  \___/ |_|  \_/  \___|  \__||_| |_| \___| |_|  |_| \___/  \__,_| \___||_|
        
    def search(self):
        """
        Search for a zero-correlation distinguisher optimized for key recovery
        """

        if self.time_limit != -1:
            time_limit = datetime.timedelta(seconds=self.time_limit)
        else:
            time_limit = None
    
        start_time = time.time()
        ####################################################################################################
        ####################################################################################################
        self.cp_model = minizinc.Model()
        self.cp_model.add_file(self.mzn_file_name)
        self.cp_inst = minizinc.Instance(solver=self.cp_solver, model=self.cp_model)
        self.cp_inst["RU"] = self.RU
        self.cp_inst["RL"] = self.RL
        self.cp_inst["KR"] = self.KR
        self.cp_inst["NPT"] = self.NPT        
        self.result = self.cp_inst.solve(timeout=time_limit, 
                                         processes=self.num_of_threads, 
                                         #verbose=True, 
                                         debug_output=Path("./debug_output.txt", intermediate_solutions=True),                                         
                                         optimisation_level=2)
        ####################################################################################################
        ####################################################################################################
        elapsed_time = time.time() - start_time
        print("Elapsed time: {:0.02f} seconds".format(elapsed_time))

        if self.result.status == minizinc.Status.OPTIMAL_SOLUTION or self.result.status == minizinc.Status.SATISFIED or \
                            self.result.status == minizinc.Status.ALL_SOLUTIONS:           
            attack_summary = self.print_attack_parameters()
            attack_summary += line_separator + "\n"
            print(attack_summary)
            draw = Draw(self, output_file_name=self.output_file_name, attack_summary=attack_summary)
            draw.generate_attack_shape()
        elif self.result.status == minizinc.Status.UNSATISFIABLE:
            print("Model is unsatisfiable")
        else:
            print("Solving process was interrupted")
    #############################################################################################################################################
    #############################################################################################################################################
    #############################################################################################################################################

    def print_attack_parameters(self):
        """
        Print attack parameters
        """                   
        str_output = line_separator + "\n"
        str_output += "Distinguisher parameters:\n"
        str_output += "Number of forwrd rounds:         {:02d}\n".format(self.RU + 1)
        str_output += "Number of backward rounds:       {:02d}\n".format(self.RL + 1)    
        self.lazy_tweak_cells_numeric = dict()
        for i in range(2):
            for j in range(16):
                if self.result["contradict"][0][i][j] == 1:
                    self.lazy_tweak_cells_numeric[(i, j)] = j
        self.lazy_tweak_cells_numeric_zero = [self.lazy_tweak_cells_numeric.get((0, i)) for i in range(16)]
        self.lazy_tweak_cells_numeric_one = [self.lazy_tweak_cells_numeric.get((1, i)) for i in range(16)]
        lazy_tweak_cells = ["T{:01d}[{:02d}] ".format(i, j) for (i, j) in self.lazy_tweak_cells_numeric.keys()]
        str_output += "Tweak cells that are active at most {:02d} times:\n".format(self.NPT) + ", ".join(lazy_tweak_cells) + "\n"        
        str_output += line_separator + "\n"
        for r in range(self.KR - 2):
            str_output += "Tweak permutation[{:02d}]:\n".format(r)
            for i in range(4):
                str_output += "  "
                for j in range(4):
                    str_output += "{:02d} ".format(self.result["tk_permutation_per_round"][r][4*i + j])
                str_output += "\n"
            str_output += line_separator + "\n"
        return str_output    

#############################################################################################################################################
#############################################################################################################################################
#############################################################################################################################################
#  _   _                    ___         _                __                   
# | | | | ___   ___  _ __  |_ _| _ __  | |_  ___  _ __  / _|  __ _   ___  ___ 
# | | | |/ __| / _ \| '__|  | | | '_ \ | __|/ _ \| '__|| |_  / _` | / __|/ _ \
# | |_| |\__ \|  __/| |     | | | | | || |_|  __/| |   |  _|| (_| || (__|  __/
#  \___/ |___/ \___||_|    |___||_| |_| \__|\___||_|   |_|   \__,_| \___|\___|
    
def loadparameters(args):
    '''
    Extract parameters from the argument list and input file
    '''

    # Load default values
    params = {
              "RU": 3,
              "RL": 3,
              "KR": 14,
              "cp_solver_name" : "ortools",
              "num_of_threads" : 8,
              "time_limit" : None,
              "output_file_name" : "output.tex"}
    # Overwrite parameters if they are set on command line
    if args.RU is not None:
        params["RU"] = args.RU
    if args.RL is not None:
        params["RL"] = args.RL
    if args.KR is not None:
        params["KR"] = args.KR
    if args.sl is not None:
        params["cp_solver_name"] = args.sl
    if args.p is not None:
        params["num_of_threads"] = args.p
    if args.tl is not None:
        params["time_limit"] = args.tl
    if args.o is not None:
        params["output_file_name"] = args.o
    return params

def main():
    '''
    Parse the arguments and start the request functionality with the provided
    parameters
    '''

    parser = ArgumentParser(description="This tool finds the optimum integral distinguisher for Qarma-v2-64 block cipher\n",
                            formatter_class=RawTextHelpFormatter)    

    parser.add_argument("-RU", default=5, type=int, help="Number of rounds for EU")
    parser.add_argument("-RL", default=5, type=int, help="Number of rounds for EL")
    parser.add_argument("-KR", default=14, type=int, help="Number of rounds for key recovery")


    parser.add_argument("-sl", default="ortools", type=str,
                        choices=['gecode', 'chuffed', 'coin-bc', 'gurobi', 'picat', 'scip', 'choco', 'ortools'],
                        help="choose a cp solver\n") 
    parser.add_argument("-p", default=8, type=int, help="number of threads for solvers supporting multi-threading\n")    
    parser.add_argument("-tl", default=4000, type=int, help="set a time limit for the solver in seconds\n")
    parser.add_argument("-o", default="output.tex", type=str, help="output file including the Tikz code to generate the shape of the attack\n")

    # Parse command line arguments and construct parameter list
    args = parser.parse_args()
    params = loadparameters(args)
    integral__distinguisher = IntegralDistinguisher(params)    
    print(line_separator)
    print("Searching for an integral distinguisher for Qarma-v2-64 with the following parameters")
    print("RU:              {}".format(params["RU"]))
    print("RL:              {}".format(params["RL"]))    
    print("CP solver:       {}".format(params["cp_solver_name"]))
    print("No. of threads:  {}".format(params["num_of_threads"]))
    print("Time limit:      {}".format(params["time_limit"]))
    print(line_separator)
    integral__distinguisher.search()
    
#############################################################################################################################################
#############################################################################################################################################
#############################################################################################################################################

if __name__ == "__main__":
    main()
