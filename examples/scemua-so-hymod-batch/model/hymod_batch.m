function modelOutput = hymod_batch(conf,constants,init,parVec,priorTimes)

% Runs the HYMOD model

% % 

% % LICENSE START
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% %                                                                           % %
% % MMSODA Toolbox for MATLAB                                                 % %
% %                                                                           % %
% % Copyright (C) 2013 Netherlands eScience Center                            % %
% %                                                                           % %
% % Licensed under the Apache License, Version 2.0 (the "License");           % %
% % you may not use this file except in compliance with the License.          % %
% % You may obtain a copy of the License at                                   % %
% %                                                                           % %
% % http://www.apache.org/licenses/LICENSE-2.0                                % %
% %                                                                           % %
% % Unless required by applicable law or agreed to in writing, software       % %
% % distributed under the License is distributed on an "AS IS" BASIS,         % %
% % WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  % %
% % See the License for the specific language governing permissions and       % %
% % limitations under the License.                                            % %
% %                                                                           % %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % LICENSE END


mmsodaUnpack()

tStart = priorTimes(1);
tEnd = priorTimes(end);

x_loss = 0.0;

% Initialize slow tank state
x_slow = 2.3503/(Rs*convFactor);

% Initialize state(s) of quick tank(s)
x_quick(1:3,1) = 0;

outflow = [];

nPrior = numel(priorTimes);

tempOutput = repmat(NaN,[1,nPrior]);


for iPrior = 1:nPrior-1

    tPrev = priorTimes(iPrior);
    tNow = tPrev;
    tNext = priorTimes(iPrior+1);

    while tNow < tNext
        iNow = find(tNow == numTime);

        Pval = dailyPrecip(iNow+1,1);
        PETval = dailyPotEvapTrans(iNow+1,1);

        % Compute excess precipitation and evaporation
        [UT1,UT2,x_loss] = excess(x_loss,cmax,bexp,Pval,PETval);

        % Partition UT1 and UT2 into quick and slow flow component
        UQ = fQuickFlow*UT2 + UT1;
        US = (1-fQuickFlow)*UT2;

        % Route slow flow component with single linear reservoir
        inflow = US;
        [x_slow,outflow] = linres(x_slow,inflow,outflow,Rs);
        QS = outflow;

        % Route quick flow component with linear reservoirs
        inflow = UQ;
        for k=1:3
            [x_quick(k),outflow] = linres(x_quick(k),inflow,outflow,Rq);
            inflow = outflow;
        end


         tNow = tNow + 1;
    end
    % Compute total flow for timestep
    tempOutput(1,iPrior+1) = (QS + outflow)*convFactor;
end


% nStatesKF = conf.nStatesKF;
% nNOKF = conf.nNOKF;
% nPrior = numel(conf.priorTimes);
% stateValuesKFNew(1:nStatesKF,1:nPrior) = repmat(NaN,[nStatesKF,nPrior]);
% 
% valuesNOKFNew(1:nNOKF,1) = NaN;
% valuesNOKFNew(1:nNOKF,2:nPrior) = tempOutput(1,2:nPrior);


modelOutput(2:nPrior) = tempOutput(1,2:nPrior);





