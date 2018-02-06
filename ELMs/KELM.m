% KELM - Kernel ExTreme Learning Machine Class
%   Train and Predict a SLFN based on Kernel ExTreme Learning Machine
%
%   This code was implemented based on the following paper:
%
%   [1] Guang-Bin Huang, Hongming Zhou, Xiaojian Ding, and Rui Zhang, ExTreme 
%       Learning Machine for Regression and Multiclass Classification. 
%       Trans. Sys. Man Cyber. Part B 42, 2 (April 2012), 513-529. 
%       http://dx.doi.org/10.1109/TSMCB.2011.2168604 
%       (http://ieeexplore.ieee.org/document/6035797/)
%
%   Attributes: 
%       Attributes between *.* must be informed.
%       K-ELM objects must be created using name-value pair arguments (see the Usage Example).
%
%                    kernelType:   Function that defines kernel  
%                Accepted Values:   one of these strings (function handles will be supported in the future):
%                                       'RBF_kernel':     Radial Basis Function (default)
%                                       'lin_kernel':     Linear
%                                       'poly_kernel':    Polynomial
%                                       'wav_kernel':     Wavelet
%
%                   kernelParam:   Kernel Parameter 
%                Accepted Values:   Any positive real number (defaut = 0.1).
%
%       regularizationParameter:   Regularization Parameter 
%                Accepted Values:   Any positive real number (defaut = 1000).
%
%       Attributes generated by the code:
%
%                            xTr:   Training data (defined when the model is trained).
%
%                   outputWeight:   Weight matrix that connects the hidden
%                                   layer to the output layer
%
%   Methods:
%
%       obj = KELM(varargin):       Creates KELM objects. varargin should be in
%                                   pairs. Look attributes.
%
%       obj = obj.train(X,Y):       Method for training. X is the input of size N x n,
%                                   where N is (# of samples) and n is the (# of features).
%                                   Y is the output of size N x m, where m is (# of multiple outputs)
%                            
%       Yhat = obj.predict(X):      Predicts the output for X.
%
%   Usage Example:
%
%       load iris_dataset.mat
%       X    = irisInputs';
%       Y    = irisTargets';
%       kelm  = KELM();
%       kelm  = kelm.train(X, Y);
%       Yhat = kelm.predict(X)

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
%       date:       Jan/2018

classdef KELM
    properties
        kernelType = 'RBF_kernel'
        kernelParam = 0.1
        regularizationParameter = 1000
        outputWeight = []        
        xTr = []
    end
    methods
        function obj = KELM(varargin)
            for i = 1:2:nargin
                obj.(varargin{i}) = varargin{i+1};
            end
        end
        
        function omega = kernel_matrix(self,Xte)            
            nb_data = size(self.xTr,1);
            if strcmp(self.kernelType,'RBF_kernel')
                if nargin<2
                    XXh = sum(self.xTr.^2,2)*ones(1,nb_data);
                    omega = XXh + XXh' - 2*(self.xTr*self.xTr');
                    omega = exp(-omega./self.kernelParam(1));
                else
                    XXh1 = sum(self.xTr.^2,2)*ones(1,size(Xte,1));
                    XXh2 = sum(Xte.^2,2)*ones(1,nb_data);
                    omega = XXh1 + XXh2' - 2*self.xTr*Xte';
                    omega = exp(-omega./self.kernelParam(1));
                end
                
            elseif strcmp(self.kernelType,'lin_kernel')
                if nargin<2
                    omega = self.xTr*self.xTr';
                else
                    omega = self.xTr*Xte';
                end
                
            elseif strcmp(self.kernelType,'poly_kernel')
                if nargin<4
                    omega = (self.xTr*self.xTr' + self.kernelParam(1)).^self.kernelParam(2);
                else
                    omega = (self.xTr*Xte' + self.kernelParam(1)).^self.kernelParam(2);
                end
                
            elseif strcmp(self.kernelType,'wav_kernel')
                if nargin<2
                    XXh = sum(self.xTr.^2,2)*ones(1,nb_data);
                    omega = XXh+XXh' - 2*(self.xTr*self.xTr');
                    
                    XXh1 = sum(self.xTr,2)*ones(1,nb_data);
                    omega1 = XXh1 - XXh1';
                    omega = cos(self.kernelParam(3)*omega1./self.kernelParam(2)).*exp(-omega./self.kernelParam(1));
                    
                else
                    XXh1 = sum(self.xTr.^2,2)*ones(1,size(Xte,1));
                    XXh2 = sum(Xte.^2,2)*ones(1,nb_data);
                    omega = XXh1+XXh2' - 2*(self.xTr*Xte');
                    
                    XXh11 = sum(self.xTr,2)*ones(1,size(Xte,1));
                    XXh22 = sum(Xte,2)*ones(1,nb_data);
                    omega1 = XXh11 - XXh22';
                    
                    omega = cos(self.kernelParam(3)*omega1./self.kernelParam(2)).*exp(-omega./self.kernelParam(1));
                end
            end
        end
        
        function self = train(self, X, Y)
            self.xTr = X;
            Omega_train = kernel_matrix(self);
            self.outputWeight=((Omega_train + speye(size(Y,1))/self.regularizationParameter)\(Y));
        end
        function Yhat = predict(self, Xte)
            Omega_test = kernel_matrix(self, Xte);
            Yhat = Omega_test' * self.outputWeight;
        end
    end
end