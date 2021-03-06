function varargout = mmsodaPlotPaCo(conf,evalResults,varargin)
% <a href="matlab:web(fullfile(mmsodaroot,'html','mmsodaPlotPaCo.html'),'-helpbrowser')">View HTML documentation for this function in the help browser</a>


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

standardize = true;
invAxis = repmat(false,[1,conf.nOptPars]);

nRows = size(evalResults,1);
nSamples = conf.nSamples;
iterSelection = nRows+[-5*nSamples+1:0];

authorizedOptions = {'standardize',...
                     'invAxis',...
                     'iterSelection'};

% parse input from varargin here
mmsodaParsePairs


parCols = conf.parCols;
nSamples = numel(iterSelection);

muRecords = repmat(mean(evalResults(iterSelection,parCols),1),[nSamples,1]);

flag = 0; % standard deviation calculated with n-1 in the divisor

sigmaRecords = repmat(std(evalResults(iterSelection,parCols),flag,1),[nSamples,1]);


invArray = repmat((~invAxis)*1+invAxis*-1,[nSamples,1]);


if standardize
    M = invArray.*(evalResults(iterSelection,parCols)-muRecords)./sigmaRecords;
else
    M = invArray.*evalResults(iterSelection,parCols);
end

minLim = min(M(:));
maxLim = max(M(:));

hold on
for k=conf.parCols
    if invAxis(1,k-1)
        s = '-1\cdot';
    else
        s = '';
    end
    if numel(conf.parNamesTex)>=(k-1) && ~isempty(conf.parNamesTex{k-1})
        arrayOfHandles(k-1,1) = text(k,minLim+(maxLim-minLim)*1.05,...
            [s,conf.parNamesTex{k-1}],...
            'interpreter','tex',...
            'horizontalalign','center',...
            'verticalalignment','middle');
    else
        arrayOfHandles(k-1,1) = text(k,minLim+(maxLim-minLim)*1.05,...
            [s,conf.parNames{k-1}],...
            'interpreter','none',...
            'horizontalalign','center',...
            'verticalalignment','middle');
    end
end


arrayOfHandles(conf.nOptPars+[1:conf.nOptPars],1) =...
    plot([conf.parCols;conf.parCols],[minLim;maxLim],...
    'color',0.8*[1,1,1]);

arrayOfHandles(2*conf.nOptPars+[1:nSamples],1) = plot(conf.parCols,M,'-k');

set(gca,'xlim',[min(conf.parCols),max(conf.parCols)]+[-1,1]*0.5)
set(gca,'ylim',[minLim,maxLim])
set(gca,'xtick',conf.parCols,'xticklabel',{})


if standardize
    arrayOfHandles(end+1,1) = ylabel('standardized parameter value');
else
    arrayOfHandles(end+1,1) = ylabel('parameter value');
end



set(gcf,'numbertitle','off','name',mfilename)




if nargout==1
    varargout = {arrayOfHandles};
end
