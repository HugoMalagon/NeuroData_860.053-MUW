function dQsim = simulateSessions(RL, T, nSessions)
% simulateSessions  Pseudo-sessions of the fitted RL agent (null for value coding).
%
%   dQsim = simulateSessions(RL, T, nSessions)
%
%   RL is the output of fitRLmodel, T the trials table.
%   Runs the fitted RL agent (alpha, beta, rRatio) through the SAME
%   sequence of trials (block reward probabilities of table T) and returns
%   its value difference Qg - Qs before each choice, for the valid trials
%   of T. One column per simulated session.
%
%   Course: MUW 860.053
pG = T.ProbGamble / 100; pS = T.ProbSafe / 100;
nT = height(T);
dQsim = zeros(sum(T.Valid), nSessions);
for s = 1:nSessions
    qg = 0; qs = 0; d = zeros(nT, 1);
    for t = 1:nT
        d(t) = qg - qs;
        if rand < 1 / (1 + exp(-RL.beta * (qg - qs)))   % agent chooses gamble
            r = rand < pG(t);
            qg = qg + RL.alpha * (r * RL.rRatio - qg);
        else                                           % agent chooses safe
            r = rand < pS(t);
            qs = qs + RL.alpha * (r - qs);
        end
    end
    dQsim(:, s) = d(T.Valid);
end
end
