% EM-ELM - Error Minimized Extreme Learning Machine Class
%   Train and Predict a SLFN based on Error Minimized Extreme Learning Machine Class
%
%   This code was implemented based on the following paper:
%
%
%   [1] Guorui Feng, Guang-Bin Huang, Qingping Lin, & Gay, R. (2009).
%       Error Minimized Extreme Learning Machine With Growth of
%       Hidden Nodes and Incremental Learning.
%       IEEE Transactions on Neural Networks, 20(8), 1352–1357.
%       https://doi.org/10.1109/TNN.2009.2024147
%
%
%   Attributes:
%       Attributes between *.* must be informed.
%       EMELM objects must be created using name-value pair arguments (see the Usage Example).
%
%         *numberOfInputNeurons*:   Number of neurons in the input layer.
%                Accepted Values:   Any positive integer.
%
%          numberOfHiddenNeurons:   Initial number of neurons in the hidden layer
%                                   After training, this attribute contains the number of
%                                   neurons in the hidden layer.
%                Accepted Values:   Any positive integer (defaut = 1).
%
%       maxNumberOfHiddenNeurons:   Maximum number of neurons in the hidden layer
%                Accepted Values:   Any positive integer (defaut = 1000).
%
%                   maximumError:   Maximum error (used as stopping criterion)
%                Accepted Values:   Any positive real number. (default = 1e-3)
%
%          numberOfNeuronsByStep:   Number of neurons added in each iteration
%                Accepted Values:   Any positive integer number. (default = 1)
%
%             activationFunction:   Activation funcion for hidden layer
%                Accepted Values:   Function handle (see [1]) or one of these strings:
%                                       'sig':     Sigmoid (default)
%                                       'sin':     Sine
%                                       'hardlim': Hard Limit
%                                       'tribas':  Triangular basis function
%                                       'radbas':  Radial basis function
%
%                           seed:   Seed to generate the pseudo-random values.
%                                   This attribute is for reproducible research.
%                Accepted Values:   RandStream object or a integer seed for RandStream.
%
%       Attributes generated by the code:
%
%                    inputWeight:   Weight matrix that connects the input
%                                   layer to the hidden layer
%
%            biasOfHiddenNeurons:   Bias of hidden units
%
%                   outputWeight:   Weight matrix that connects the hidden
%                                   layer to the output layer
%
%   Methods:
%
%          obj = EMELM(varargin):   Creates IELM objects. varargin should be in
%                                   pairs. Look attributes
%
%           obj = obj.train(X,Y):   Method for training. X is the input of size N x n,
%                                   where N is (# of samples) and n is the (# of features).
%                                   Y is the output of size N x m, where m is (# of multiple outputs)
%
%          Yhat = obj.predict(X):   Predicts the output for X.
%
%   Usage Example:
%
%       load iris_dataset.mat
%       X    = irisInputs';
%       Y    = irisTargets';
%       emelm  = EMELM('numberOfInputNeurons', 4, 'numberOfHiddenNeurons',100);
%       emelm  = emelm.train(X, Y);
%       Yhat = emelm.predict(X)
%
%   License:
%
%   Permission to use, copy, or modify this software and its documentation
%   for educational and research purposes only and without fee is here
%   granted, provided that this copyright notice and the original authors'
%   names appear on all copies and supporting documentation. This program
%   shall not be used, rewritten, or adapted as the basis of a commercial
%   software or hardware product without first obtaining permission of the
%   authors. The authors make no representations about the suitability of
%   this software for any purpose. It is provided "as is" without express
%   or implied warranty.
%
%       Federal University of Espirito Santo (UFES), Brazil
%       Computers and Neural Systems Lab. (LabCISNE)
%       Authors:    F. K. Inaba, B. L. S. Silva, D. L. Cosmo
%       email:      labcisne@gmail.com
%       website:    github.com/labcisne/ELMToolbox
%       date:       Feb/2018

classdef EMELM < ELM
    properties
        maxNumberOfHiddenNeurons  = 1000
        pseudoInv
        maxError = 1e-3
        nodesByIteration = 1
    end
    properties (Access = private)
        H
    end
    
    methods
        function self = EMELM(varargin)
            self = self@ELM('numberOfHiddenNeurons',1,varargin{:});
        end
        
        function pi = pseudoinverse(~,h)
            if size(h,1)>=size(h,2)
                pi = pinv(h' * h) * h';
            else
                pi = h' * pinv(h * h');
            end
        end
        
        function self = train(self, X, Y)
            auxTime = toc;
            %Train with initial number of hidden neurons
            tempH = X*self.inputWeight + repmat(self.biasOfHiddenNeurons,size(X,1),1);
            self.H = self.activationFunction(tempH);
            
            self.pseudoInv = self.pseudoinverse(self.H);
            self.outputWeight = self.pseudoInv * Y;
            
            E = norm(self.H*self.outputWeight - Y,'fro');
            
            while (self.numberOfHiddenNeurons < self.maxNumberOfHiddenNeurons) && (E > self.maxError)
                
                self.numberOfHiddenNeurons = self.numberOfHiddenNeurons + self.nodesByIteration;
                
                Wnew = rand(self.seed, self.numberOfInputNeurons, self.nodesByIteration)*2-1;
                Bnew = rand(self.seed, 1, self.nodesByIteration);
                self.inputWeight = [self.inputWeight, Wnew];
                self.biasOfHiddenNeurons = [self.biasOfHiddenNeurons, Bnew];
                
                tempH = X*Wnew + repmat(Bnew,size(X,1),1);
                deltaH = self.activationFunction(tempH);
                clear tempH;
                
                Dk = (self.H*self.pseudoInv);
                Dk = self.pseudoinverse( (eye(size(Dk)) - Dk)*deltaH );
                Uk = self.pseudoInv*(eye(size(Dk,2)) - deltaH*Dk);
                self.pseudoInv = [Uk; Dk];
                
                self.outputWeight = self.pseudoInv*Y;
                self.H = [self.H, deltaH];
                
                
                E = norm(self.H*self.outputWeight - Y,'fro');
                %                 disp(E)
                
            end
            self.trainTime = toc - auxTime;
        end
        
    end
end
