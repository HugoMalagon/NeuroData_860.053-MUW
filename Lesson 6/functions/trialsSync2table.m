function T = trialsSync2table(Trials_Sync, SR)
% trialsSync2table  Convert the 19-column Trials_Sync matrix into a table.
%
%   T = trialsSync2table(Trials_Sync, SR)
%
%   Named columns are much easier to read than column numbers:
%   T.Rewarded instead of Trials_Sync(:,14). Event times (columns 15-19,
%   in sampling points) are converted to SECONDS with the sampling rate SR
%   so they are directly comparable with the spike times in STMtx.
%
%   Trials_Sync columns -> table variables
%     1  Trial start (s, behaviour clock)    -> (not kept, different clock)
%     3  Trial duration (s)                  -> TrialDuration_s
%     4  Block number                        -> Block
%     5  Gamble arm (Right=1, Left=0)        -> GambleSide
%     6  Probability big reward (%)          -> ProbGamble
%     7  Probability small reward (%)        -> ProbSafe
%     8  Amount big reward                   -> AmountGamble
%     9  Amount small reward                 -> AmountSafe
%    10  Previous wheel-not-stopping count   -> WheelFails
%    11  Not responding trial                -> NotResponding
%    12  Chosen side (Right=1, Left=0)       -> ChosenSide
%    13  Chosen arm (Gamble=1, Safe=0)       -> ChoseGamble
%    14  Rewarded trial                      -> Rewarded
%    15  Start of trial (samples)            -> TrialStart_s
%    16  Cue presentation (samples)          -> Cue_s
%    17  Start of response window (samples)  -> ResponseWindow_s
%    18  Reward period (samples)             -> Reward_s
%    19  End of trial (samples)              -> TrialEnd_s
%   Extra: Trial (index) and Valid (responded AND block > 0)
%
%   Course: MUW 860.053 (see also TrialsSync_to_DimitrisTable.m, Flexi-Gambling)

n = size(Trials_Sync, 1);
T = table((1:n)', 'VariableNames', {'Trial'});
T.Block            = Trials_Sync(:, 4);
T.GambleSide       = Trials_Sync(:, 5);
T.ProbGamble       = Trials_Sync(:, 6);
T.ProbSafe         = Trials_Sync(:, 7);
T.AmountGamble     = Trials_Sync(:, 8);
T.AmountSafe       = Trials_Sync(:, 9);
T.WheelFails       = Trials_Sync(:, 10);
T.NotResponding    = Trials_Sync(:, 11);
T.ChosenSide       = Trials_Sync(:, 12);
T.ChoseGamble      = Trials_Sync(:, 13);
T.Rewarded         = Trials_Sync(:, 14);
T.TrialStart_s     = Trials_Sync(:, 15) / SR;
T.Cue_s            = Trials_Sync(:, 16) / SR;
T.ResponseWindow_s = Trials_Sync(:, 17) / SR;
T.Reward_s         = Trials_Sync(:, 18) / SR;
T.TrialEnd_s       = Trials_Sync(:, 19) / SR;
T.TrialDuration_s  = Trials_Sync(:, 3);
T.Valid            = T.NotResponding == 0 & T.Block > 0 & ~isnan(T.ChoseGamble);
end
