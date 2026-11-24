% Lesson6_Students_plain.m
% Plain-script version of the live script Lesson6_Students.mlx, for
% computers on which the live script does not open. The text, code and
% exercises are the same; only the layout is different.
%
% How to use this file
% * Open it in the MATLAB Editor and set the Current Folder to the folder
%   "Lesson 6" (the folder that contains this file).
% * Run it one section at a time: click inside a section (each section
%   starts at a line that begins with %%) and press Ctrl+Enter (macOS:
%   Cmd+Enter), or click Run Section in the Editor tab.
% * Results appear in the Command Window, figures in figure windows.
% * The lesson text is in the comments. Marks such as *bold*, _italic_
%   and |code| are the formatting of the live script.
% * Write your answers where it says "% >>> YOUR CODE HERE <<<".

%% Lesson 6 - MATLAB for Neuroscience Data
% *Processing and Interpretation of Neuroscience Data (860.053-MUW)* -
% Vered Kellner and Hugo Malagon Vina
%
% In this lesson you learn the MATLAB tools that you will use in every
% following lesson, directly on real data: 141 neurons recorded in the
% prelimbic cortex of a mouse performing a gambling task.
%
% *Learning goals*
%
% * Create, inspect and index arrays (vectors, matrices), including logical indexing and NaN
% * Load real electrophysiology data and understand its format
% * Use the data containers of neuroscience: cell arrays, structs and tables
% * Write scripts, functions, loops and conditions
% * Make clear, publication-style figures and save them
% * Organise an analysis in a reproducible way
%
% *How to use this live script*
%
% # Set the MATLAB *Current Folder* to the folder |Lesson 6| (browse to
% it in the Current Folder panel or with the folder bar at the top). All
% file paths in this script start from this folder.
% # Run section 0 (Setup) *first*, every time you open MATLAB. It adds the
% helper functions of the course to the MATLAB path (explained in section 0).
% # Run the script one section at a time (Run Section, or Ctrl+Enter).
% # Blocks marked *FOR YOU!!* are exercises (|L6-E.x|) or questions
% (|L6-Q.x|). Write your answers in the empty code block below them.
% # Homework is at the end of the script, followed by an optional section
% *Going further* with extra material and exercises (|L6-X.x|).
%
% *Where does the output appear?*
%
% * The results of a section (numbers, text, figures) appear in the live
% script itself. You choose where: *View* tab > *Output on Right* (next to
% the code) or *Output Inline* (below each section). The same two buttons
% are at the top right of the live script. Try both and keep the one you like.
% * To run only some lines, select them and press *F9* (macOS: Shift+F7),
% or right-click > _Evaluate Selection_. The result then appears in the
% *Command Window*, not in the live script. Very handy to test one line.
% * You can also type any command in the Command Window, for example the
% name of a variable to see its content: the live script and the Command
% Window share the same workspace.

%% 0. Setup (demo)
% *Demo:* the teacher does this section live on the projector; do the
% same on your computer.
%
% Every analysis script should start the same way: clean workspace, close
% figures, and make sure MATLAB finds the data and the helper functions.
%
% *The MATLAB path.* MATLAB can only use a function file (|.m|) that is in
% the Current Folder or in a folder on its *path* (the list of folders where
% MATLAB looks for functions). The helper functions of this course are in
% the subfolder |functions|, so we add it with |addpath('functions')|.
%
% * This is not permanent: run this section again every time you open MATLAB.
% * If you see the error _Unrecognized function or variable 'stmtx2cell'_,
% the path was not added (or the Current Folder is wrong).
% * |which stmtx2cell| shows which file MATLAB uses; |path| lists all folders on the path.
% * Same with the mouse: right-click the |functions| folder in the Current
% Folder panel > _Add to Path_ > _Selected Folders_.
clear; close all; clc
assert(isfolder('data'), ['Data folder not found. Set the Current Folder ' ...
    'to the "Lesson 6" folder and run again.'])
addpath('functions')       % helper functions provided for this lesson
which stmtx2cell           % check: MATLAB now finds the helper functions
if ~isfolder('figures'), mkdir('figures'); end
if ~isfolder('results'), mkdir('results'); end

%% 1. Everything is an array
% In MATLAB nearly everything is an array (a matrix). A scalar is 1x1, a
% row vector is 1xN, a column vector is Nx1 and a matrix is MxN.
%
% * Commas or spaces separate columns: |[1 2 3]| or |[1, 2, 3]|
% * Semicolons separate rows: |[1; 2; 3]|
%
% A semicolon at the END of a line hides the output.
a = 5                       % scalar
b = [1 2 3 4]               % row vector
c = [1; 2; 3; 4]            % column vector
M = [1 2; 3 4]              % 2x2 matrix
size(M)                     % [rows columns]
numel(b)                    % number of elements
whos                        % what is in the workspace?

%% FOR YOU!! - L6-E.1
% Create a matrix |M2| with 4 rows and 5 columns (any numbers). Then check
% that you built it correctly: use |size(M2)| to see its rows and columns,
% |size(M2,1)| to confirm it has 4 rows, |size(M2,2)| to confirm it has 5
% columns, and |numel(M2)| to confirm it holds 20 numbers in total.
%
% *L6-Q.1* What is the difference between the four outputs?

% >>> YOUR CODE HERE <<<

%% 2. Operations: element-wise versus matrix
% MATLAB applies operations to whole arrays at once ("vectorisation").
%
% * Careful: |*| is MATRIX multiplication (linear algebra, rarely needed
% in this course). To multiply element by element use |.*|. The same holds
% for |/| versus |./| and |^| versus |.^|.
% * The apostrophe |'| *transposes* an array: rows become columns, so a
% row vector becomes a column vector and vice versa.
x = [1 2 3];
y = [4 5 6];
elementwise = x .* y        % [4 10 18]
squared     = x .^ 2
x'                          % transpose: the row x becomes a column
1 + 2 / 3                   % operator precedence: / before +
(1 + 2) / 3

% A neuroscience example: spike times in seconds -> milliseconds
spikes_s  = [0.0123 0.1502 0.1519 0.8004];
spikes_ms = spikes_s * 1000
isi_ms    = diff(spikes_ms)             % inter-spike intervals

%% FOR YOU!! - L6-E.2
% A neuron fired 312 spikes in a 25-s recording. Compute its firing rate
% (Hz). Then compute the firing rate of five neurons at once: they fired
% |[312 45 1020 7 88]| spikes in the same 25 s.
%
% *L6-Q.2* Why do we write |isi_ms = diff(spikes_ms)| and not a loop?

% >>> YOUR CODE HERE <<<

%% 3. Creating vectors and time axes
% The colon operator |start:step:stop| and |linspace| create regular
% vectors. In signal processing we always need a *time axis*: N samples
% taken at a sampling rate |fs| (samples per second).
v1 = 1:5
v2 = 0:0.25:1
v3 = linspace(0, 10, 5)
zeros(2, 3)
ones(1, 4)
rand(2, 2)            % uniform random numbers between 0 and 1
randn(1, 3)           % normally distributed random numbers

fs = 1000;                         % sampling rate (Hz)
t  = (0:1999) / fs;                % 2 s of time, sample 1 at t = 0
theta = sin(2*pi*8*t);             % an 8 Hz "theta" oscillation
plot(t, theta)
xlabel('Time (s)'); ylabel('Amplitude'); title('8 Hz sine sampled at 1 kHz')

%% FOR YOU!! - L6-E.3
% Create 3 s of a signal sampled at 500 Hz that is the sum of a 6 Hz sine
% (amplitude 1) and a 40 Hz sine (amplitude 0.3) plus Gaussian noise with
% SD 0.2 (use |randn|). Plot the whole signal. The 3 s are too dense to
% see the 40 Hz wave, so then zoom in on the first 0.5 s with
% |xlim([0 0.5])| (|xlim| sets the limits of the x axis).

% >>> YOUR CODE HERE <<<

%% 4. Indexing and logical indexing
% MATLAB indices start at 1. |A(i,j)| is row i, column j; |:| means "all";
% |end| is the last element.
A = magic(4)
A(2, 3)
A(2, :)           % whole row 2
A(:, end)         % last column
A(1:2, [1 4])     % rows 1-2, columns 1 and 4

%%
% *Logical indexing* is the most useful trick in data analysis: a
% comparison gives a logical (true/false) array that selects elements.
spk = [0.05 0.21 0.22 0.48 0.51 0.90 1.30 1.31 1.32 1.80];   % spike times (s)
inWindow = spk >= 0.2 & spk < 1.0        % logical vector
spk(inWindow)                            % the spikes inside [0.2, 1.0)
nSpikesInWindow = sum(inWindow)          % true counts as 1
find(inWindow)                           % their positions

%%
% *NaN* ("not a number") marks missing values. Most functions return NaN
% if any input is NaN, unless you ask them to ignore it.
data = [3 5 NaN 7];
mean(data)
mean(data, 'omitnan')
isnan(data)
data(~isnan(data))           % remove the NaNs

%% FOR YOU!! - L6-E.4
% # Create |RandomM| = a 15x3 matrix of random numbers (|rand|).
% # Make a COPY of it in which every value between 0.2 and 0.6 is NaN (do
% not change |RandomM|).
% # Compute the mean of each column of the copy, ignoring the NaNs.
% # (Optional) With the vector |spk| above: how many spikes occur after
% 1 s? What are the inter-spike intervals of those spikes?

% >>> YOUR CODE HERE <<<

%% 5. Getting help
% There are thousands of functions. |help name| prints a short description
% in the Command Window; |doc name| opens the full documentation with
% examples. Your own functions also have help: the comment block at the
% top of the file.
help mad
help stmtx2cell          % a helper function written for this course

%%
% *When MATLAB complains: the 5 most common errors*
%
% An error message is red and names the line where it happened. Read it
% calmly: it usually says exactly what is wrong. Come back to this list
% whenever you get stuck.
%
% * _Unrecognized function or variable 'x'_: a typo (MATLAB is case
% sensitive: |Spikes| is not |spikes|), the section that creates |x| was
% not run yet, or the Current Folder / path is wrong (section 0).
% * _Index exceeds the number of array elements_: you asked for an
% element that does not exist, for example element 10 of a vector with 9
% elements. Check the size with |size| or |numel|.
% * _Arrays have incompatible sizes for this operation_: you combined
% arrays of different lengths (for example 1x3 and 1x4). Check both with
% |size|. *Careful:* a row combined with a column gives NO error - MATLAB
% silently builds a matrix (|[1 2 3] + [1; 2; 3]| is 3x3).
% * _Brace indexing is not supported for variables of this type_: you used
% curly braces |{}| on something that is not a cell array (section 8).
% Use round brackets |()| instead.
% * _At least one END is missing_: every |for|, |if| and |function| needs
% its own |end|.
%
% Copying the error message into a search engine or an AI assistant
% usually explains it quickly, but make sure you understand the fix before
% you use it.

%% FOR YOU!! - L6-E.5
% Use |help| or |doc| to find out what |median| and |mad| do. Compute the
% median and the MAD (median absolute deviation, in MATLAB |mad(x, 1)|) of
% the values |[1 2 3 4 100]| and compare with |mean| and |std|. *Careful:*
% without the 1, |mad(x)| computes the _mean_ absolute deviation, which is
% not robust.
%
% *L6-Q.3* Which pair is more robust to the outlier 100? Why is that
% important when we set a threshold to detect spikes (next lesson)?

% >>> YOUR CODE HERE <<<

%% 6. Loading real data: the spike time matrix
% The file |STMtx.mat| contains the spike times of all neurons of one
% session. *Each column is one neuron* and holds its spike times in
% seconds. Neurons fire different numbers of spikes, but a matrix needs
% columns of equal length: the shorter columns are padded with NaN.
load(fullfile('data', 'STMtx.mat'))
size(STMtx)
STMtx(1:5, 1:4)              % first spikes of the first 4 neurons
nNeurons = size(STMtx, 2)

% spikes of neuron 1 (remove the NaN padding)
spikes1 = STMtx(~isnan(STMtx(:, 1)), 1);
% fprintf prints a text with numbers in it (explained in section 10)
fprintf('Neuron 1 fired %d spikes between %.1f and %.1f s\n', ...
    numel(spikes1), spikes1(1), spikes1(end));

% number of spikes of EVERY neuron at once: count the non-NaN entries
nSpikes = sum(~isnan(STMtx));
recDuration = max(STMtx(:)) - min(STMtx(:));      % recording length (s); max and min ignore NaN
firingRate  = nSpikes / recDuration;              % Hz

%% FOR YOU!! - L6-E.6
% # Which neuron has the highest firing rate, and which the lowest? (Hint:
% |max|, |min| with two outputs.)
% # Plot a histogram of the firing rates of all neurons. Try 20 bins, and
% then the same with a logarithmic x axis (|histogram(log10(firingRate))|).
%
% *L6-Q.4* How are firing rates distributed across neurons? Why can a
% log scale help?

% >>> YOUR CODE HERE <<<

%% 7. Loops and conditions
% Often you want to repeat the same code many times, or run some code only
% in some cases.
%
% * A *for loop* repeats the code between |for| and |end| once for each
% value: |for n = 1:5| runs the code with |n = 1|, then |n = 2|, ... up to 5.
% * An *if* block runs code only when a condition is true. The optional
% |else| part runs when it is false.
% * (A *while* loop repeats as long as a condition is true. We will rarely need it.)
%
% Every |for| and every |if| needs its own |end|. Indent the code inside
% (the Editor does it for you): then you see at a glance where a block ends.
for n = 1:3
    n                       % no semicolon: shows n at every repetition
end

%%
% A real example: count the neurons that fire faster than 5 Hz. Start a
% counter at 0 and add 1 every time the condition is true.
nFast = 0;
for n = 1:nNeurons
    if firingRate(n) > 5
        nFast = nFast + 1;
    end
end
nFast

%%
% *Loops versus vectorised code.* Many loops can be replaced by one line
% that works on the whole array at once. Logical indexing (section 4)
% gives the same answer. Vectorised code is shorter and faster (a
% timing demo is in the optional section at the end of the lesson).
%
% Rule of thumb: when one vectorised line does the job, use it; use a loop
% when every step needs several lines (one analysis per neuron or per
% trial - you will write many such loops in the next lessons).
sum(firingRate > 5)

%% FOR YOU!! - L6-E.7
% Change the loop above so that it counts the neurons that fire *less*
% than 1 Hz. Then check your answer with one vectorised line.

% >>> YOUR CODE HERE <<<

%% 8. Cell arrays: one container per neuron
% A cell array can hold elements of different sizes, which is the natural
% way to store spike times: |spikeTimes{n}| is the vector of neuron n.
% Use curly braces |{}| to get the content, round brackets |()| to get a
% smaller cell array.
%
% *A first look at functions.* You have already used many functions:
% |size|, |mean|, |diff|, |numel| ... A function takes *inputs* in round
% brackets and gives back *outputs*: |n = numel(x)|. (In section 11 you
% will write your own.) To apply the same function to every cell we use
% |cellfun|:
%
% * |cellfun(@numel, spikeTimes)| runs |numel| on every cell and collects
% the results in a vector. The |@| gives MATLAB the function itself (a
% _function handle_) instead of running it immediately.
% * |@(s) s(1)| is an *anonymous function*: a one-line function without a
% file. |s| is its input (here: the content of one cell) and |s(1)| (its
% first element) is what it returns.
%
% For now you only need to *recognise* this notation: you will meet
% |@(...)| again in later lessons, also with |arrayfun| (the same as
% |cellfun|, but for every element of a vector). If you want to practise
% it, see L6-X.1 in the optional section at the end of the lesson.
spikeTimes = cell(1, nNeurons);    % empty cell array, filled by the loop
for n = 1:nNeurons
    s = STMtx(:, n);
    spikeTimes{n} = s(~isnan(s));
end
spikeTimes(1:3)                 % a 1x3 cell array
numel(spikeTimes{5})            % the spikes of neuron 5
nSpikes_cell = cellfun(@numel, spikeTimes);   % apply a function to every cell
isequal(nSpikes_cell, nSpikes)

% The same conversion is packed in the helper function stmtx2cell:
spikeTimes = stmtx2cell(STMtx);

% An anonymous function in action: the first spike time of every neuron
firstSpike = cellfun(@(s) s(1), spikeTimes);
firstSpike(1:5)

%% 9. Tables: the behavioural data
% The behaviour of the session is stored in |Trials_Sync|, a 19-column
% matrix (one row per trial). Columns 15-19 are event times in *sampling
% points* at 20 kHz. Reading |Trials_Sync(:,14)| is hard to remember...
load(fullfile('data', 'Trials_Sync.mat'))
size(Trials_Sync)
Trials_Sync(1:3, :)

%%
% ... so we convert it to a *table* with named columns and event times in
% seconds (same clock as the spike times). Open |trialsSync2table.m| to
% see which column is which. The task:
%
% * The mouse stops a wheel for 1 s (trial start), a cue appears, and it
% chooses Left or Right: one side is the *Gamble* arm, the other the *Safe* arm.
% * Safe: small reward (1 drop) with 90 % probability.
% * Gamble: big reward (4 drops) with a probability that changes between
% blocks (75 %, then 22.5 %, then 12.5 %).
SR = 20000;
T = trialsSync2table(Trials_Sync, SR);
head(T)

%%
% Working with tables:
T.Rewarded(1:10)'                                % one column
block2 = T(T.Block == 2, :);                     % rows of block 2
height(block2)
responded = T(T.Valid, :);                       % responded trials only
mean(responded.ChoseGamble)                      % P(choose gamble)
G = groupsummary(responded, 'Block', 'mean', {'ChoseGamble', 'Rewarded'})

%% FOR YOU!! - L6-E.8
% Using the table |T| (valid trials only):
%
% # What percentage of *gamble* choices were rewarded, and what percentage
% of *safe* choices?
% # The same, separately for each block.
% # What is the mean time between the cue and the reward period in each block?
%
% Hint for 2 and 3: |groupsummary| (above) can also group by two columns
% at once: |{'Block', 'ChoseGamble'}|. The mean of a 0/1 column is a
% proportion (0.75 = 75 %).
%
% *L6-Q.5* Does the behaviour of the mouse make sense given the reward
% probabilities in each block?

% >>> YOUR CODE HERE <<<

%% 10. Printing results: disp and num2str
% |disp| shows a value or a text. Text goes between single quotes. Pieces
% of text are joined with square brackets |[ ]|, exactly as you join
% numbers into a vector.
disp('Analysis of the prelimbic session')
disp(['Neuron ' 'seven'])             % [ ] joins two pieces of text

%%
% A number must first be turned into text with |num2str|. Without it,
% MATLAB reads the number as a character code: 65 is the letter A.
['Neuron ' 65]                        % wrong: 65 is not the text '65'
['Neuron ' num2str(65)]               % right
disp(['Neuron 7 fires at ' num2str(firingRate(7)) ' Hz'])
disp(['Rounded: ' num2str(firingRate(7), 3) ' Hz'])    % 3 significant digits

%%
% The same works for the titles, labels and legends of figures, for example
% |title(['Neuron ' num2str(n)])|.
%
% *Reading box: fprintf and sprintf.* In the next lessons you will often
% see |fprintf| (prints a text) and |sprintf| (creates a text, for example
% for a title). Both fill numbers into a template: |%d| = whole number,
% |%.2f| = number with 2 decimals, |\n| = new line. You only need to be
% able to read them. This line prints the same sentence as the |disp| line
% above, with 2 decimals:
fprintf('Neuron %d fires at %.2f Hz\n', 7, firingRate(7))

%% FOR YOU!! - L6-E.9
% # With |disp| and |num2str|, print the sentence
% |Neuron 60 fired N spikes (X Hz)|, where N and X come from the variables
% |nSpikes| and |firingRate| of section 6. Show the rate with 3
% significant digits.
% # (Optional) Print the same sentence for neurons 1 to 5 with a |for| loop.

% >>> YOUR CODE HERE <<<

%% 11. Functions
% *Functions* package code that you use again and again. A function lives
% in its own file whose name equals the function name. Open
% |functions/countSpikesInWindows.m| to see an example with a help block,
% inputs and outputs. Here we use it to get the firing rate of every
% neuron in the 1 s after the cue of every trial:
[ratesCue, countsCue] = countSpikesInWindows(spikeTimes, T.Cue_s, T.Cue_s + 1);
size(ratesCue)          % trials x neurons

%%
% *A function only gives back its outputs.* A function has its own,
% separate workspace. Only the variables listed as outputs in its first
% line (|function [rates, counts] = ...|) come back to you, with the names
% you choose when you call it (here |ratesCue|, |countsCue|). Every other
% variable created inside (|nW|, |nN|, |counts| ...) disappears when the
% function ends, and the function cannot see or change the variables of
% your script - it only knows its inputs.
exist('nW', 'var')      % 0: nW only existed INSIDE countSpikesInWindows
exist('counts', 'var')  % 0: inside it was called counts; here it is countsCue

%%
% *Debugging*: click on a line number in the Editor to set a breakpoint
% (red dot), run, then step line by line (Step) and look at the variables.
% To ask the user for input use |x = input('How many? ')| and to wait use
% |pause| - try them in a script, not in this live script.

%% FOR YOU!! - L6-E.10
% # Write a function file |myFiringRate.m| with the signature
% |rate = myFiringRate(spk, t1, t2)| that returns the firing rate of the
% spike times |spk| between |t1| and |t2|. Test it on neuron 60 between
% 100 s and 200 s.
% # (Optional) Using a *for loop* over trials and your function, compute
% the firing rate of neuron 60 in every trial between |T.TrialStart_s| and
% |T.TrialEnd_s|. Compare with |countSpikesInWindows|.
%
% *How to create a function file, step by step*
%
% * *Home > New > Function* opens a new file with a template (or use
% *New Script* and type everything yourself).
% * Replace the template with three lines: the first line
% |function rate = myFiringRate(spk, t1, t2)|, one line that computes
% |rate| (count the spikes between |t1| and |t2| with logical indexing, as
% in section 4, and divide by the duration), and |end|.
% * Save it as |myFiringRate.m| in the |Lesson 6| folder. *The file
% name must be the same as the function name*, otherwise MATLAB does not
% find it.
% * Come back to this live script and call it below:
% |myFiringRate(spikeTimes{60}, 100, 200)|.

% >>> YOUR CODE HERE <<<

%% 12. Figures that communicate
% A good figure has labelled axes with units, a title, a legend when
% needed and readable fonts. |tiledlayout| / |nexttile| arrange panels
% (the modern version of |subplot|). |exportgraphics| saves a figure.
V = T(T.Valid, :);
fig = figure('Position', [100 100 900 350]);
tl = tiledlayout(1, 2, 'TileSpacing', 'compact');
title(tl, 'Session overview')

nexttile     % A: running average of the choices
plot(V.Trial, movmean(V.ChoseGamble, 10), 'LineWidth', 1.5)
hold on
xline(V.Trial(find(diff(V.Block)) + 1), '--k')
xlabel('Trial'); ylabel('P(gamble), 10-trial average'); ylim([0 1])
title('A  Choices across blocks')

nexttile     % B: histogram
histogram(log10(firingRate), 20)
xlabel('log_{10} firing rate (Hz)'); ylabel('Neurons'); title('B  Firing rates')

exportgraphics(fig, fullfile('figures', 'Lesson6_session_overview.png'), 'Resolution', 200)

%% FOR YOU!! - L6-E.11
% # Make a figure for neuron 60: its firing rate in the 1 s after the cue
% (|ratesCue(:,60)|) against the trial number, coloured by block (|scatter|
% with the block as colour: |scatter(x, y, 20, T.Block, 'filled')|). Label
% everything and save it as a PNG in the |figures| folder.
% # (Optional) Add a second panel with a box plot of the same rates per
% block (|boxchart|). Use |tiledlayout(1, 2)| and |nexttile| as in the
% figure above.

% >>> YOUR CODE HERE <<<

%% 13. Saving results and good practices
% Save derived results, never overwrite raw data.
%
% A convenient container for results is a *struct*: it groups related
% information under field names, written with a dot. A field can hold
% anything: a number, a vector, a text, a table.
results.area       = 'Prelimbic cortex';
results.nNeurons   = nNeurons;
results.firingRate = firingRate;
results.ratesCue   = ratesCue;
results.created    = datetime('now');
results                       % shows all fields
results.area                  % access one field
fieldnames(results)

%%
% |save| writes variables to a |.mat| file (|load| reads them back). With
% |'-struct'| every field becomes a separate variable in the file. A table
% can also be saved as a |.csv| text file, which Excel, R or Python can
% open, with |writetable| (read it back with |readtable|).
save(fullfile('results', 'Lesson6_results.mat'), '-struct', 'results')
writetable(T, fullfile('results', 'Trials_Table.csv'));
dir('results')

%%
% *Good practices for analysis code*
%
% * One folder per project with |data|, |functions|, |results|, |figures|.
% * Use relative paths built with |fullfile| (they work on Windows, macOS and Linux).
% * Never edit raw data files by hand. Every figure and number must be
% produced by a saved script.
% * Put repeated code in functions, with a help block.
% * Set the random seed (|rng(1)|) when you use random numbers, so results
% can be reproduced.
% * Comment WHY you do something, not only what.
% * Use version control (git) for your code.

%% HOMEWORK (optional)
% Write each solution in a new script. Several are inspired by MATLAB Cody
% (<https://www.mathworks.com/matlabcentral/cody/problems>).
%
% # *Every other element*: write a function that returns the odd-numbered
% elements of a vector (|[1 3 2 4 3 5]| -> |[1 2 3]|).
% # *Remove bad trials*: given a matrix, remove all rows that contain at
% least one NaN.
% # *Binning spikes*: with |histcounts|, count the spikes of neuron 60 in
% 1-s bins over the whole session and plot the result as a firing-rate
% time course. Mark the block changes with |xline|.
% # *Bursts*: for neuron 60 find all ISIs shorter than 10 ms. What
% fraction of its spikes belong to such "bursts"?
% # *Win-stay / lose-shift*: using |T|, compute how often the mouse chose
% the same arm after a rewarded trial, and how often it switched after an
% unrewarded trial.
% # *Decision time*: |Reward_s - Cue_s| (cue to outcome) is the time the
% mouse needed to choose. Plot its distribution per block. Are there
% outliers? (Do not use |ResponseWindow_s|: the response window always
% opens ~67 ms after the cue, it is task timing, not behaviour.)
% # *Session loop*: the folder |data| could contain many sessions. Use
% |dir(fullfile('data', '*.mat'))| to list the files and print their names
% and sizes with a loop and |fprintf|.
% # *Save a summary*: create a struct |stats| with the mean and SD of the
% firing rates, the number of trials and your name, save it to
% |results/stats.mat| and print a confirmation.
% # *Fibonacci*: return the n-th Fibonacci number with a loop (|fib(7)=13|).
% # *Colour by condition*: redo panel A of section 12 with a separate
% line for gamble and safe choices of the rewarded trials only.

%% GOING FURTHER (optional)
% Extra material and exercises for those who want more, or to practise at
% home. Nothing here is needed for the next lessons.

%% Loops versus vectorised code: a timing demo (optional)
% |tic| starts a stopwatch and |toc| reads it. The same computation
% (k^2 + 3k for a million numbers), once with a loop and once vectorised:
tic
y1 = zeros(1, 1e6);
for k = 1:1e6
    y1(k) = k^2 + 3*k;
end
tLoop = toc;
tic
k = 1:1e6;
y2 = k.^2 + 3*k;
tVec = toc;
fprintf('loop %.4f s, vectorised %.4f s, identical: %d\n', tLoop, tVec, isequal(y1, y2));

%% FOR YOU!! - L6-X.1 (optional): cellfun with your own anonymous function
% Use |cellfun| to compute the *median inter-spike interval* of every
% neuron. (Hint: |@(s) median(diff(s))|.) Which neuron has the shortest
% median ISI? Is it also the neuron with the highest firing rate?

% >>> YOUR CODE HERE <<<

%% More ways to build text (optional)
% * *Strings*: double quotes create a _string_ (|"Neuron"|), single quotes
% a _character vector_ (|'Neuron'|). Both hold text and most functions
% accept both. Strings are joined with |+| and turn numbers into text
% automatically: |"Neuron " + 7|. Careful: |[ ]| joins character vectors,
% |+| joins strings; mixing them up is a classic source of errors.
% * |sprintf| builds a text from a template: |%d|, |%.2f|, and |%03d| = a
% whole number with 3 digits, padded with zeros (useful for file names
% that sort correctly: |neuron007|, |neuron060|, |neuron141|).
% * |compose| does the same for many numbers at once and returns an array
% of strings (one per number), for example for legends.
name = "Neuron " + 7
msg  = sprintf('Neuron %d fires at %.2f Hz', 7, firingRate(7))
labels = compose("Neuron %d", 1:3)
fname = fullfile('figures', sprintf('raster_neuron%03d.png', 7))

%% FOR YOU!! - L6-X.2 (optional): labels from the table
% Create a string array with the labels |"Block 1 (75%)"|, |"Block 2 (22.5%)"|
% and |"Block 3 (12.5%)"| using the gamble probabilities stored in the
% table (|T.ProbGamble|) - do not type the numbers yourself.
%
% Hints: |find(T.Block == b, 1)| gives the first row of block |b|. In a
% template, |%g| prints a number without trailing zeros and |%%| prints
% the % sign itself.

% >>> YOUR CODE HERE <<<

%% More figure types (optional)
% Two more panels for the session overview of section 12: a bar plot with
% error bars (mean +/- SEM per block), and an image of a matrix
% (|imagesc|): the rate of every neuron (columns) in every trial (rows)
% after the cue, z-scored per neuron (|zscore|: subtract the mean, divide
% by the SD), so that neurons with different rates become comparable.
fig2 = figure('Position', [100 100 900 350]);
tiledlayout(1, 2, 'TileSpacing', 'compact')

nexttile     % bar plot with mean and SEM
m   = groupsummary(V, 'Block', 'mean', 'ChoseGamble');
sdv = groupsummary(V, 'Block', 'std',  'ChoseGamble');
sem = sdv.std_ChoseGamble ./ sqrt(m.GroupCount);
bar(m.Block, m.mean_ChoseGamble); hold on
errorbar(m.Block, m.mean_ChoseGamble, sem, 'k.', 'LineWidth', 1.5)
xlabel('Block'); ylabel('P(gamble)'); title('Mean +/- SEM')

nexttile     % image of a matrix (trials x neurons)
imagesc(zscore(ratesCue(T.Valid, :)))
xlabel('Neuron'); ylabel('Trial'); title('Rate after cue (z-score)')
cb = colorbar; cb.Label.String = 'z';
clim([-2 2])
