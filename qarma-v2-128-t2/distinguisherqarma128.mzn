% MIT License

% Copyright (c) 2023 Hosein Hadipour

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:

% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.


int: RU;
int: RL;
int: RD;
int: NPT;
int: min_ru_rl;
int: max_ru_rl;
int: KR;
RD = RU + RL;
min_ru_rl = min([RU, RL]);
max_ru_rl = max([RU, RL, 2]);

constraint assert(RU >= 1,"Invalid value for RU: " ++
                "RU must be greater than or equal to 1");
constraint assert(RL >= 1,"Invalid value for RL: " ++
                "RL must be greater than or equal to 1");

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ____                    _                _         _           __                _____                        _                  ____         _                _         _       
%  / ___| ___   _ __   ___ | |_  _ __  __ _ (_) _ __  | |_  ___   / _|  ___   _ __  |_   _|__      __ ___   __ _ | | __ ___  _   _  / ___|   ___ | |__    ___   __| | _   _ | |  ___ 
% | |    / _ \ | '_ \ / __|| __|| '__|/ _` || || '_ \ | __|/ __| | |_  / _ \ | '__|   | |  \ \ /\ / // _ \ / _` || |/ // _ \| | | | \___ \  / __|| '_ \  / _ \ / _` || | | || | / _ \
% | |___| (_) || | | |\__ \| |_ | |  | (_| || || | | || |_ \__ \ |  _|| (_) || |      | |   \ V  V /|  __/| (_| ||   <|  __/| |_| |  ___) || (__ | | | ||  __/| (_| || |_| || ||  __/
%  \____|\___/ |_| |_||___/ \__||_|   \__,_||_||_| |_| \__||___/ |_|   \___/ |_|      |_|    \_/\_/  \___| \__,_||_|\_\\___| \__, | |____/  \___||_| |_| \___| \__,_| \__,_||_| \___|
%                                                                                                                            |___/                                                   
% Constraints for the tweakey schedule 

array[0..(RD - 1), 0..1, 0..31] of var 0..1: any_or_nonzero_subtweakey;
array[0..(RD - 1), 0..1, 0..31] of var 0..1: only_nonzero_subtweakeys;
array[0..31] of int: tweakey_permutation = array1d(0..31, [1, 10, 14, 22, 18, 25, 29, 21, 0, 8, 12, 4, 19, 27, 31, 23, 17, 26, 30, 6, 2, 9, 13, 5, 16, 24, 28, 20, 3, 11, 15, 7]);
array[0..31] of int: inv_tweakey_permutation = array1d(0..31, [8, 0, 20, 28, 11, 23, 19, 31, 9, 21, 1, 29, 10, 22, 2, 30, 24, 16, 4, 12, 27, 7, 3, 15, 25, 5, 17, 13, 26, 6, 18, 14]);

array[0..max_ru_rl + KR, 0..31] of var int: tkp_sequence;
constraint forall (i in 0..31) (tkp_sequence[0, i] = i);
constraint forall (n in 1..max_ru_rl + KR, i in 0..31) (tkp_sequence[n, i] = tweakey_permutation[tkp_sequence[n - 1, i]]);

array[0..(RD + KR - 1), 0..31] of var int: tk_permutation_per_round;
constraint forall (i in 0..31) (tk_permutation_per_round[0, i] = i);
% different interpretations of the concept of the reduced round (how to initiate the second tweakey permutation)
% constraint forall(i in 0..31) (tk_permutation_per_round[1, i] = tkp_sequence[max_ru_rl - 1, i]);
constraint forall(i in 0..31) (tk_permutation_per_round[1, i] = tkp_sequence[min_ru_rl - 1, i]);
% constraint forall(i in 0..31) (tk_permutation_per_round[1, i] = tkp_sequence[ceil((KR - 2) / 2) - 1, i]);

constraint forall(r in 2..(RD + KR - 1))
(
    if r mod 2 == 0 then
    (
        forall(i in 0..31) (tk_permutation_per_round[r, i] = tweakey_permutation[tk_permutation_per_round[r - 2, i]])
    ) else
    (
        forall(i in 0..31) (tk_permutation_per_round[r, i] = inv_tweakey_permutation[tk_permutation_per_round[r - 2, i]])
    ) endif
);

array[0..15] of int: state_permutation = array1d(0..15, [0, 11, 6, 13, 10, 1, 12, 7, 5, 14, 3, 8, 15, 4, 9, 2]);
array[0..15] of int: inv_state_permutation = array1d(0..15, [0, 5, 15, 10, 13, 8, 2, 7, 11, 14, 4, 1, 6, 3, 9, 12]);
array[0..(RD - 1)] of var 0..1: exchange_row_enable; % 1 if XR is applied and 0 if XR is not applied (XR: Exchange Rows).

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ____                    _                _         _           __                _____  _   _ 
%  / ___| ___   _ __   ___ | |_  _ __  __ _ (_) _ __  | |_  ___   / _|  ___   _ __  | ____|| | | |
% | |    / _ \ | '_ \ / __|| __|| '__|/ _` || || '_ \ | __|/ __| | |_  / _ \ | '__| |  _|  | | | |
% | |___| (_) || | | |\__ \| |_ | |  | (_| || || | | || |_ \__ \ |  _|| (_) || |    | |___ | |_| |
%  \____|\___/ |_| |_||___/ \__||_|   \__,_||_||_| |_| \__||___/ |_|   \___/ |_|    |_____| \___/ 
                                                                                                
% Constraints for EU 

array[0..RU, 0..1, 0..15] of var 0..3: forward_mask_x;
array[0..RU, 0..1, 0..15] of var -2..15: forward_class_x;
constraint forall(r in 0..RU, i in 0..1, j in 0..15)(link_mask_class(forward_mask_x[r, i, j], forward_class_x[r, i, j]));

array[0..(RU - 1), 0..1, 0..15] of var 0..3: forward_mask_sbx;
array[0..(RU - 1), 0..1, 0..15] of var -2..15: forward_class_sbx;
constraint forall(r in 0..(RU - 1), i in 0..1, j in 0..15)(link_mask_class(forward_mask_sbx[r, i, j], forward_class_sbx[r, i, j]));

array[0..(RU - 1), 0..1, 0..3, 0..1] of var 0..3: forward_mask_aux;
array[0..(RU - 1), 0..1, 0..3, 0..1] of var -2..15: forward_class_aux;
constraint forall(r in 0..(RU - 1), i in 0..1, j in 0..3, k in 0..1)(link_mask_class(forward_mask_aux[r, i, j, k], forward_class_aux[r, i, j, k]));

% Exclude all-zero input mask
var 0..96: inputmask_distinguisher;
constraint inputmask_distinguisher = sum(i in 0..1, j in 0..15)(forward_mask_x[0, i, j]);
constraint inputmask_distinguisher >= 1;

constraint forall(r in 0..(RU - 1), i in 0..1, j in 0..15)
(
    sb_operation(forward_mask_x[r, i, j], forward_mask_sbx[r, i, j])
);

array[0..(RU - 1), 0..1, 0..15] of var 0..3: forward_mask_exx;
array[0..(RU - 1), 0..1, 0..15] of var -2..15: forward_class_exx;
constraint forall(r in 0..(RU - 1), i in 0..1, j in 0..15)(link_mask_class(forward_mask_exx[r, i, j], forward_class_exx[r, i, j]));

constraint forall(r in 0..(RU - 1))
(
    if ((r mod 2) == (RU mod 2)) then 
    (
        forall(i in 0..1, j in 8..15)
        (
            forward_mask_exx[r, i, j] = forward_mask_sbx[r, i, j]
        )
        /\
        forall(i in 0..1, j in 0..7)
        (
            forward_mask_exx[r, i, j] = forward_mask_sbx[r, (i + 1) mod 2, j]
        )
        /\
        exchange_row_enable[r] = 1
    ) else
    (
        forall(i in 0..1, j in 0..15)
        (
            forward_mask_exx[r, i, j] = forward_mask_sbx[r, i, j]
        )
        /\
        exchange_row_enable[r] = 0
    ) endif
);

% MixColumn
constraint forall(r in 0..(RU - 1), i in 0..1, j in 0..3)
(
    mix_column( forward_mask_exx[r, i, state_permutation[0 + j]], forward_class_exx[r, i, state_permutation[0 + j]],
                forward_mask_exx[r, i, state_permutation[4 + j]], forward_class_exx[r, i, state_permutation[4 + j]],
                forward_mask_exx[r, i, state_permutation[8 + j]], forward_class_exx[r, i, state_permutation[8 + j]],
                forward_mask_exx[r, i, state_permutation[12 + j]], forward_class_exx[r, i, state_permutation[12 + j]],
                forward_mask_x[r + 1, i, 0 + j], forward_class_x[r + 1, i, 0 + j], 
                forward_mask_x[r + 1, i, 4 + j], forward_class_x[r + 1, i, 4 + j],
                forward_mask_x[r + 1, i, 8 + j], forward_class_x[r + 1, i, 8 + j],
                forward_mask_x[r + 1, i, 12 + j], forward_class_x[r + 1, i, 12 + j],
                forward_mask_aux[r, i, j, 0], forward_class_aux[r, i, j, 0],
                forward_mask_aux[r, i, j, 1], forward_class_aux[r, i, j, 1])                
);

% link the subtweakey and the internal state
constraint forall(r in 0..(RU - 1), t in 0..1, i in 0..1, j in 0..15)
(
    if forward_mask_exx[r, i, j] == 3 then
        any_or_nonzero_subtweakey[r, t, tk_permutation_per_round[r, 16*i + j]] = 1
        /\
        only_nonzero_subtweakeys[r, t, tk_permutation_per_round[r, 16*i + j]] = 0
    elseif forward_mask_exx[r, i, j] >= 1 then
        any_or_nonzero_subtweakey[r, t, tk_permutation_per_round[r, 16*i + j]] = 1
        /\ 
        only_nonzero_subtweakeys[r, t, tk_permutation_per_round[r, 16*i + j]] = 1
    else
        any_or_nonzero_subtweakey[r, t, tk_permutation_per_round[r, 16*i + j]] = 0
        /\
        only_nonzero_subtweakeys[r, t, tk_permutation_per_round[r, 16*i + j]] = 0
    endif
);

% we need to place the eXchangeRows here

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ____                    _                _         _           __                _____  _     
%  / ___| ___   _ __   ___ | |_  _ __  __ _ (_) _ __  | |_  ___   / _|  ___   _ __  | ____|| |    
% | |    / _ \ | '_ \ / __|| __|| '__|/ _` || || '_ \ | __|/ __| | |_  / _ \ | '__| |  _|  | |    
% | |___| (_) || | | |\__ \| |_ | |  | (_| || || | | || |_ \__ \ |  _|| (_) || |    | |___ | |___ 
%  \____|\___/ |_| |_||___/ \__||_|   \__,_||_||_| |_| \__||___/ |_|   \___/ |_|    |_____||_____|
% Constraints for EL                                                                                                

array[0..RL, 0..1, 0..1, 0..15] of var 0..3: backward_mask_x;
array[0..RL, 0..1, 0..1, 0..15] of var -2..15: backward_class_x;
constraint forall(r in 0..RL, t in 0..1, i in 0..1, j in 0..15)(link_mask_class(backward_mask_x[r, t, i, j], backward_class_x[r, t, i, j]));

array[0..RL, 0..1, 0..1, 0..15] of var 0..3: backward_mask_sbx;
array[0..RL, 0..1, 0..1, 0..15] of var -2..15: backward_class_sbx;
constraint forall(r in 0..RL, t in 0..1, i in 0..1, j in 0..15)(link_mask_class(backward_mask_sbx[r, t, i, j], backward_class_sbx[r, t, i, j]));

array[0..(RL - 1), 0..1, 0..1, 0..3, 0..1] of var 0..3: backward_mask_aux;
array[0..(RL - 1), 0..1, 0..1, 0..3, 0..1] of var -2..15: backward_class_aux;
constraint forall(r in 0..(RL - 1), t in 0..1, i in 0..1, j in 0..3, k in 0..1)(link_mask_class(backward_mask_aux[r, t, i, j, k], backward_class_aux[r, t, i, j, k]));

% Exlude all-zero output mask
var 0..96: outputmask_distinguisher1;
constraint outputmask_distinguisher1 = sum(i in 0..1, j in 0..15)(backward_mask_x[0, 0, i, j]);
constraint outputmask_distinguisher1 != 0;
var 0..96: outputmask_distinguisher2;
constraint outputmask_distinguisher2 = sum(i in 0..1, j in 0..15)(backward_mask_x[0, 1, i, j]);
constraint outputmask_distinguisher2 != 0;

% SB Operation
constraint forall(r in 0..RL, t in 0..1, i in 0..1, j in 0..15)
(
    sb_operation(backward_mask_x[r, t, i, j], backward_mask_sbx[r, t, i, j])
);

array[0..(RL - 1), 0..1, 0..1, 0..15] of var 0..3: backward_mask_exx;
array[0..(RL - 1), 0..1, 0..1, 0..15] of var -2..15: backward_class_exx;
constraint forall(r in 0..(RL - 1), t in 0..1, i in 0..1, j in 0..15)(link_mask_class(backward_mask_exx[r, t, i, j], backward_class_exx[r, t, i, j]));

constraint forall(r in 0..(RL - 1), t in 0..1)
(
    if (r mod 2 == (RL mod 2)) then 
    (
        forall(i in 0..1, j in 8..15)
        (
            backward_mask_exx[r, t, i, j] = backward_mask_sbx[r, t, i, j]
        )
        /\
        forall(i in 0..1, j in 0..7)
        (
            backward_mask_exx[r, t, i, j] = backward_mask_sbx[r, t, (i + 1) mod 2, j]
        )
        /\
        exchange_row_enable[RU + r] = 1
    ) else
    (
        forall(i in 0..1, j in 0..15)
        (
            backward_mask_exx[r, t, i, j] = backward_mask_sbx[r, t, i, j]
        )
        /\
        exchange_row_enable[RU + r] = 0
    ) endif
);

% MixColumn
constraint forall(r in 0..(RL - 1), t in 0..1, i in 0..1, j in 0..3)
(
    mix_column( backward_mask_exx[r, t, i, state_permutation[0 + j]], backward_class_exx[r, t, i, state_permutation[0 + j]],
                backward_mask_exx[r, t, i, state_permutation[4 + j]], backward_class_exx[r, t, i, state_permutation[4 + j]],
                backward_mask_exx[r, t, i, state_permutation[8 + j]], backward_class_exx[r, t, i, state_permutation[8 + j]],
                backward_mask_exx[r, t, i, state_permutation[12 + j]], backward_class_exx[r, t, i, state_permutation[12 + j]],
                backward_mask_x[r + 1, t, i, 0 + j], backward_class_x[r + 1, t, i, 0 + j],
                backward_mask_x[r + 1, t, i, 4 + j], backward_class_x[r + 1, t, i, 4 + j],
                backward_mask_x[r + 1, t, i, 8 + j], backward_class_x[r + 1, t, i, 8 + j],
                backward_mask_x[r + 1, t, i, 12 + j], backward_class_x[r + 1, t, i, 12 + j],
                backward_mask_aux[r, t, i, j, 0], backward_class_aux[r, t, i, j, 0],
                backward_mask_aux[r, t, i, j, 1], backward_class_aux[r, t, i, j, 1])
);

% link the subtweakey and the internal state
constraint forall(r in 0..(RL - 1), t in 0..1, i in 0..1, j in 0..15)
(
    if backward_mask_exx[r, t, i, j] == 3 then
        any_or_nonzero_subtweakey[RD - r - 1, t, tk_permutation_per_round[RD - r - 1, 16*i + j]] = 1
        /\
        only_nonzero_subtweakeys[RD - r - 1, t, tk_permutation_per_round[RD - r - 1, 16*i + j]] = 0
    elseif backward_mask_exx[r, t, i, j] >= 1 then
        any_or_nonzero_subtweakey[RD - r - 1, t, tk_permutation_per_round[RD - r - 1, 16*i + j]] = 1
        /\
        only_nonzero_subtweakeys[RD - r - 1, t, tk_permutation_per_round[RD - r - 1, 16*i + j]] = 1
    else
        any_or_nonzero_subtweakey[RD - r - 1, t, tk_permutation_per_round[RD - r - 1, 16*i + j]] = 0
        /\
        only_nonzero_subtweakeys[RD - r - 1, t, tk_permutation_per_round[RD - r - 1, 16*i + j]] = 0
    endif
);

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ____                                   _                _    _              ____               _                    _  _        _    _               
%  / ___| _   _   __ _  _ __  __ _  _ __  | |_  ___   ___  | |_ | |__    ___   / ___| ___   _ __  | |_  _ __  __ _   __| |(_)  ___ | |_ (_)  ___   _ __  
% | |  _ | | | | / _` || '__|/ _` || '_ \ | __|/ _ \ / _ \ | __|| '_ \  / _ \ | |    / _ \ | '_ \ | __|| '__|/ _` | / _` || | / __|| __|| | / _ \ | '_ \ 
% | |_| || |_| || (_| || |  | (_| || | | || |_|  __/|  __/ | |_ | | | ||  __/ | |___| (_) || | | || |_ | |  | (_| || (_| || || (__ | |_ | || (_) || | | |
%  \____| \__,_| \__,_||_|   \__,_||_| |_| \__|\___| \___|  \__||_| |_| \___|  \____|\___/ |_| |_| \__||_|   \__,_| \__,_||_| \___| \__||_| \___/ |_| |_|
% Guarantee the contradiction in the tweakey schedule

array[0..1, 0..1, 0..31] of var 0..RD: no_of_any_or_nonzero;
array[0..1, 0..1, 0..31] of var 0..RD: no_of_only_nonzero;

constraint forall(i in 0..1, t in 0..1, j in 0..31)
(
    no_of_any_or_nonzero[i, t, j] = sum(r in 0..(RD - 1) where (r mod 2) == i)(any_or_nonzero_subtweakey[r, t, j])
    /\
    no_of_only_nonzero[i, t, j] = sum(r in 0..(RD - 1) where r mod 2 == i)(only_nonzero_subtweakeys[r, t, j])
);

array[0..1, 0..1, 0..31] of var 0..1: contradict;
constraint forall(i in 0..1, t in 0..1, j in 0..31)
(
    contradict[i, t, j] = bool2int(no_of_any_or_nonzero[i, t, j] <= NPT /\ no_of_only_nonzero[i, t, j] >= 1) + bool2int(no_of_any_or_nonzero[i, t, j] == 0)
);
constraint sum(i in 0..1, j in 0..31)(bool2int(contradict[i, 0, j] + contradict[i, 1, j] == 2)) >= 1;

constraint  (((backward_mask_x[0, 0, 0, 0] = 1 \/ backward_mask_x[0, 0, 0, 4] = 1 \/ backward_mask_x[0, 0, 0, 8] = 1 \/ backward_mask_x[0, 0, 0, 12] = 1)
            /\
            (backward_mask_x[0, 1, 0, 0] = 1 \/ backward_mask_x[0, 1, 0, 4] = 1 \/ backward_mask_x[0, 1, 0, 8] = 1 \/ backward_mask_x[0, 1, 0, 12] = 1))
            \/ 
            ((backward_mask_x[0, 0, 0, 1] = 1 \/ backward_mask_x[0, 0, 0, 5] = 1 \/ backward_mask_x[0, 0, 0, 9] = 1 \/ backward_mask_x[0, 0, 0, 13] = 1)
            /\
            (backward_mask_x[0, 1, 0, 1] = 1 \/ backward_mask_x[0, 1, 0, 5] = 1 \/ backward_mask_x[0, 1, 0, 9] = 1 \/ backward_mask_x[0, 1, 0, 13] = 1))
            \/
            ((backward_mask_x[0, 0, 0, 2] = 1 \/ backward_mask_x[0, 0, 0, 6] = 1 \/ backward_mask_x[0, 0, 0, 10] = 1 \/ backward_mask_x[0, 0, 0, 14] = 1)
            /\
            (backward_mask_x[0, 1, 0, 2] = 1 \/ backward_mask_x[0, 1, 0, 6] = 1 \/ backward_mask_x[0, 1, 0, 10] = 1 \/ backward_mask_x[0, 1, 0, 14] = 1))
            \/
            ((backward_mask_x[0, 0, 0, 3] = 1 \/ backward_mask_x[0, 0, 0, 7] = 1 \/ backward_mask_x[0, 0, 0, 11] = 1 \/ backward_mask_x[0, 0, 0, 15] = 1)
            /\
            (backward_mask_x[0, 1, 0, 3] = 1 \/ backward_mask_x[0, 1, 0, 7] = 1 \/ backward_mask_x[0, 1, 0, 11] = 1 \/ backward_mask_x[0, 1, 0, 15] = 1)))
            \/
            
            ((backward_mask_x[0, 0, 1, 0] = 1 \/ backward_mask_x[0, 0, 1, 4] = 1 \/ backward_mask_x[0, 0, 1, 8] = 1 \/ backward_mask_x[0, 0, 1, 12] = 1)
            /\
            (backward_mask_x[0, 1, 1, 0] = 1 \/ backward_mask_x[0, 1, 1, 4] = 1 \/ backward_mask_x[0, 1, 1, 8] = 1 \/ backward_mask_x[0, 1, 1, 12] = 1))
            \/ 
            ((backward_mask_x[0, 0, 1, 1] = 1 \/ backward_mask_x[0, 0, 1, 5] = 1 \/ backward_mask_x[0, 0, 1, 9] = 1 \/ backward_mask_x[0, 0, 1, 13] = 1)
            /\
            (backward_mask_x[0, 1, 1, 1] = 1 \/ backward_mask_x[0, 1, 1, 5] = 1 \/ backward_mask_x[0, 1, 1, 9] = 1 \/ backward_mask_x[0, 1, 1, 13] = 1))
            \/
            ((backward_mask_x[0, 0, 1, 2] = 1 \/ backward_mask_x[0, 0, 1, 6] = 1 \/ backward_mask_x[0, 0, 1, 10] = 1 \/ backward_mask_x[0, 0, 1, 14] = 1)
            /\
            (backward_mask_x[0, 1, 1, 2] = 1 \/ backward_mask_x[0, 1, 1, 6] = 1 \/ backward_mask_x[0, 1, 1, 10] = 1 \/ backward_mask_x[0, 1, 1, 14] = 1))
            \/
            ((backward_mask_x[0, 0, 1, 3] = 1 \/ backward_mask_x[0, 0, 1, 7] = 1 \/ backward_mask_x[0, 0, 1, 11] = 1 \/ backward_mask_x[0, 0, 1, 15] = 1)
            /\
            (backward_mask_x[0, 1, 1, 3] = 1 \/ backward_mask_x[0, 1, 1, 7] = 1 \/ backward_mask_x[0, 1, 1, 11] = 1 \/ backward_mask_x[0, 1, 1, 15] = 1));

constraint sum(j in 0..15)(backward_mask_x[0, 0, 0, j]) <= 1;
constraint sum(j in 0..15)(backward_mask_x[0, 1, 0, j]) <= 1;
constraint sum(j in 0..15)(backward_mask_x[0, 0, 1, j]) <= 1;
constraint sum(j in 0..15)(backward_mask_x[0, 1, 1, j]) <= 1;
constraint sum(i in 0..15)(bool2int(backward_mask_x[0, 0, 0, i] != backward_mask_x[0, 1, 0, i])) + 
           sum(i in 0..15)(bool2int(backward_mask_x[0, 0, 1, i] != backward_mask_x[0, 1, 1, i])) >= 1;


% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%   ___   _      _              _    _               _____                     _    _               
%  / _ \ | |__  (_)  ___   ___ | |_ (_)__   __ ___  |  ___|_   _  _ __    ___ | |_ (_)  ___   _ __  
% | | | || '_ \ | | / _ \ / __|| __|| |\ \ / // _ \ | |_  | | | || '_ \  / __|| __|| | / _ \ | '_ \ 
% | |_| || |_) || ||  __/| (__ | |_ | | \ V /|  __/ |  _| | |_| || | | || (__ | |_ | || (_) || | | |
%  \___/ |_.__/_/ | \___| \___| \__||_|  \_/  \___| |_|    \__,_||_| |_| \___| \__||_| \___/ |_| |_|
%             |__/                                                                                  
% Objective function

% constraint sum(i in 0..0, j in 0..15)(contradict[i, j]) >= 1;
% constraint contradict[1, 22] = 1;
% constraint backward_mask_x[0, 0, 4] = 0;
% constraint sum(i in {0, 4, 8, 12})(backward_mask_x[0, 0, i]) >= 1;
solve maximize inputmask_distinguisher;

% #############################################################################################################################################
% #############################################################################################################################################
% #############################################################################################################################################
%     _                 _  _  _                       _____                     _    _                    
%    / \   _   _ __  __(_)| |(_)  __ _  _ __  _   _  |  ___|_   _  _ __    ___ | |_ (_)  ___   _ __   ___ 
%   / _ \ | | | |\ \/ /| || || | / _` || '__|| | | | | |_  | | | || '_ \  / __|| __|| | / _ \ | '_ \ / __|
%  / ___ \| |_| | >  < | || || || (_| || |   | |_| | |  _| | |_| || | | || (__ | |_ | || (_) || | | |\__ \
% /_/   \_\\__,_|/_/\_\|_||_||_| \__,_||_|    \__, | |_|    \__,_||_| |_| \___| \__||_| \___/ |_| |_||___/
%                                             |___/                                                       
% Auxiliary Functions

predicate link_mask_class(var 0..3: mask_vars, var -2..15: class_vars) = 
    if (mask_vars == 0) then class_vars == 0
    elseif (mask_vars == 1) then class_vars > 0
    elseif (mask_vars == 2) then class_vars == -1
    else class_vars = -2 endif
;

predicate sb_operation(var 0..3: mask_in, var 0..3: mask_out) = 
    mask_out != 1 /\
    (mask_in + mask_out) in {0,3,4,6} /\
    mask_out >= mask_in /\
    (mask_out - mask_in) <= 1
;

predicate xor_operation(var 0..3: mask_a, var -2..15: class_a, var 0..3: mask_b, var -2..15: class_b, var 0..3: mask_c, var -2..15: class_c) = 
    if (mask_a + mask_b > 2) then
        (mask_c = 3) /\ (class_c = -2)
    elseif (mask_a + mask_b = 1) then
        (mask_c = 1) /\ (class_c = class_a + class_b)
    elseif ((mask_a == 0) /\ (mask_b == 0)) then
        (mask_c = 0) /\ (class_c = 0)
    elseif (class_a + class_b < 0) then
        (mask_c = 2) /\ (class_c = -1)
    elseif (class_a == class_b) then
        (mask_c = 0) /\ (class_c = 0)
    else
        (mask_c = 1) /\
        class_c = (bool2int((class_a mod 2) != (class_b mod 2)) + 
        bool2int(((class_a div 2) mod 2) != ((class_b div 2) mod 2)) * 2 + 
        bool2int(((class_a div 4) mod 2) != ((class_b div 4) mod 2)) * 4 +
        bool2int(((class_a div 8) mod 2) != ((class_b div 8) mod 2)) * 8)
    endif
;

predicate mix_column(var 0..3: in_mask1, var -2..15: in_class1, 
                    var 0..3: in_mask2, var -2..15: in_class2, 
                    var 0..3: in_mask3, var -2..15: in_class3, 
                    var 0..3: in_mask4, var -2..15: in_class4, 
                    var 0..3: out_mask1, var -2..15: out_class1, 
                    var 0..3: out_mask2, var -2..15: out_class2, 
                    var 0..3: out_mask3, var -2..15: out_class3, 
                    var 0..3: out_mask4, var -2..15: out_class4,
                    var 0..3: auxi_mask1, var -2..15: auxi_class1,
                    var 0..3: auxi_mask2, var -2..15: auxi_class2) =
    % The First Row
    xor_operation(in_mask3, in_class3, in_mask4, in_class4, auxi_mask1, auxi_class1) /\
    xor_operation(in_mask2, in_class2, auxi_mask1, auxi_class1, out_mask1, out_class1)
    /\
    % The Second Row
    xor_operation(in_mask1, in_class1, auxi_mask1, auxi_class1, out_mask2, out_class2)
    /\
    % The Third Row
    xor_operation(in_mask1, in_class1, in_mask2, in_class2, auxi_mask2, auxi_class2) /\
    xor_operation(auxi_mask2, auxi_class2, in_mask4, in_class4, out_mask3, out_class3)
    /\
    % The Fourth Row
    xor_operation(auxi_mask2, auxi_class2, in_mask3, in_class3, out_mask4, out_class4)
;