function [ cost, grad ] = stackedAECost(theta, inputSize, hiddenSize, ...
                                              numClasses, netconfig, ...
                                              lambda, data, labels)
                                         
% stackedAECost: Takes a trained softmaxTheta and a training data set with labels,
% and returns cost and gradient using a stacked autoencoder model. Used for
% finetuning.
                                         
% theta: trained weights from the autoencoder
% visibleSize: the number of input units
% hiddenSize:  the number of hidden units *at the 2nd layer*
% numClasses:  the number of categories
% netconfig:   the network configuration of the stack
% lambda:      the weight regularization penalty
% data: Our matrix containing the training data as columns.  So, data(:,i) is the i-th training example. 
% labels: A vector containing labels, where labels(i) is the label for the
% i-th training example


%% Unroll softmaxTheta parameter

% We first extract the part which compute the softmax gradient
softmaxTheta = reshape(theta(1:hiddenSize*numClasses), numClasses, hiddenSize);

% Extract out the "stack"
stack = params2stack(theta(hiddenSize*numClasses+1:end), netconfig);

% You will need to compute the following gradients
softmaxThetaGrad = zeros(size(softmaxTheta));
stackgrad = cell(size(stack));
numStack = numel(stack);
numCases = size(data,2);
for d = 1:numStack
    stackgrad{d}.w = zeros(size(stack{d}.w));
    stackgrad{d}.b = zeros(size(stack{d}.b));
end

cost = 0; % You need to compute this

% You might find these variables useful
M = size(data, 2);
groundTruth = full(sparse(labels, 1:M, 1));


%% --------------------------- YOUR CODE HERE -----------------------------
%  Instructions: Compute the cost function and gradient vector for 
%                the stacked autoencoder.
%
%                You are given a stack variable which is a cell-array of
%                the weights and biases for every layer. In particular, you
%                can refer to the weights of Layer d, using stack{d}.w and
%                the biases using stack{d}.b . To get the total number of
%                layers, you can use numel(stack).
%
%                The last layer of the network is connected to the softmax
%                classification layer, softmaxTheta.
%
%                You should compute the gradients for the softmaxTheta,
%                storing that in softmaxThetaGrad. Similarly, you should
%                compute the gradients for each layer in the stack, storing
%                the gradients in stackgrad{d}.w and stackgrad{d}.b
%                Note that the size of the matrices in stackgrad should
%                match exactly that of the size of the matrices in stack.
%
a_cache = cell(size(stack));
a_cache{1} = sigmoid(stack{1}.w * data + stack{1}.b);
for i = 2:numStack
    a_cache{i} = sigmoid(stack{i}.w * a_cache{i-1} + stack{i}.b);
end
M = softmaxTheta*a_cache{numStack};
M = bsxfun(@minus, M, max(M, [], 1));
softmax_predict = exp(M);
softmax_predict = softmax_predict./sum(softmax_predict,1);

cost = - sum(sum(log(softmax_predict).*groundTruth))./numCases;
softmaxThetaGrad = - (groundTruth - softmax_predict)*a_cache{numStack}'./numCases + lambda.*softmaxTheta;

delta_cache = cell(size(stack));
delta_cache{numStack} = - softmaxTheta'*(groundTruth - softmax_predict) ...
        .*a_cache{numStack}.*(1-a_cache{numStack});
for i = numStack - 1 : 1
    delta_cache{i} = stack{i + 1}.w'*delta_cache{i + 1} ...
                    .* a_cache{i}.*(1 - a_cache{i});

end

stackgrad{1}.w = delta_cache{1}*data'./numCases;
stackgrad{1}.b = mean(delta_cache{1},2) ;
for i = 2:numStack
    stackgrad{i}.w = delta_cache{i}*a_cache{i-1}'./numCases;
    stackgrad{i}.b = mean(delta_cache{i},2) ;
end
% -------------------------------------------------------------------------

%% Roll gradient vector
grad = [softmaxThetaGrad(:) ; stack2params(stackgrad)];

end


% You might find this useful
function sigm = sigmoid(x)
    sigm = 1 ./ (1 + exp(-x));
end
