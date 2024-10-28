# 为什么看似古典的GARCH时间序列模型，如今还没被淘汰？

1：解释性强，GARCH模型有清晰的数学结构，定义了波动率的来源：上一期的波动率和上一期的残差。这种结构化和透明性使其特别适合金融行业，因为金融决策需要可解释的模型。

2：小样本数据同样有效： 深度学习模型通常需要大量数据才能表现出优异的效果，而金融数据往往存在样本数量有限、结构稳定的特点。

3：专注波动率： GARCH模型专门用于捕捉金融时间序列的波动性聚集现象。金融市场中，高波动往往伴随高波动、低波动伴随低波动，形成聚集效应。GARCH模型能够自然地将这种特性融入方差建模中，而深度学习模型需要大量复杂的层级和参数调优才能达到类似的效果，且未必能达到同样的解释性。


# Garch 模型组成部分

时间序列数据预测经典模型，Garch model

对于一个时间序列 $y_t$ ,Garch 模型假设：

$y_t = \mu_t + \epsilon_t$

其中， $\mu_t$ 代表均值过程， $\epsilon_t$  是误差项，它是条件异方差过程，即具有时间相关的方差。

$\epsilon_t = \sigma_t z_t$ , $z_t$代表白噪声，通常假设 $z_t$ $\sim$  $N(0,1)$, $\sigma$ 则代表波动率

# Garch 模型公式和设想

假设一个GARCH(1,1)模型，这里模型参数的第一个'1'代表只考虑 t-1 也就是前一时期模型残差，反映了“冲击”或“新信息”的影响。 第二个'1'代表只考虑t-1 也就是前一时期波动的平方的影响，反映了波动的持久性或延续性

$\sigma^2_t = \alpha_0 + \alpha_1 \epsilon^2_{t-1} + \beta_1 \sigma^2_{t-1}$


GARCH模型的主要目的是预测下一期的波动率，GARCH模型假设下一期的波动率不仅依赖于上一期的波动率，还会受到上一期残差平方的影响。

# 黄金波动率分析预测

## 查看黄金近7年来的收盘价走势

```
df = read.csv('D:/STATA/XAUUSD_data.csv')
df = data.frame(time = as.Date(df[,1]), close = df[,5])
plot(df,type='l')
```
![plo](https://github.com/Tony980624/Time-series-forecasting/blob/main/file01/Rplt.png)

总体一直处于上升趋势

## 对收盘价进行差分，得到每日收盘价变化

```
train_index = c(1:1800)
train_data = df[train_index,]
test_data = df[-train_index,]
r = diff(train_data$close)
plot(train_data$time[-1],r,type = 'l',ylab='return',xlab = '')
```
![plot](https://github.com/Tony980624/Time-series-forecasting/blob/main/file01/Rplot01.png)

把数据分为训练测试集后，对训练数据差分后的数据(波动)趋于平稳了，而且我们观察到团簇大波动率(高波动率发生时，往往后面也是高波动率)， 所以根据初步判断GARCH模型是合适的

## 用AIC和BIC寻找模型最佳ARMA参数

![plot](https://github.com/Tony980624/Time-series-forecasting/blob/main/file01/Rplot.png)

![plot](https://github.com/Tony980624/Time-series-forecasting/blob/main/file01/Rplot02.png)

排名前二的ARMA模型和它们残差的表现



## 检查残差和残差的自相关性ACF

![plot](https://github.com/Tony980624/Time-series-forecasting/blob/main/file01/Rplot03.png)
![plot](https://github.com/Tony980624/Time-series-forecasting/blob/main/file01/Rplot04.png)
![plot](https://github.com/Tony980624/Time-series-forecasting/blob/main/file01/Rplot05.png)
![plot](https://github.com/Tony980624/Time-series-forecasting/blob/main/file01/Rplot06.png)


平方残差表现出较强的自相关性，尽管残差本身的自相关性似乎很低。我们将此解读为可能存在条件异方差的证据。

## 添加GARCH部分

ARMA 模型擅长处理均值的时间序列结构，但它假设残差的方差是恒定的（即同方差）。当残差的条件异方差性显著时，说明数据存在波动性聚集（volatility clustering）现象，即较大或较小的波动往往会连续出现。这种情况在金融时间序列（如股票收益率）中较为常见，此时 ARMA 模型难以准确描述数据的波动特征。GARCH 模型（广义条件异方差模型）通过引入条件方差结构来描述波动性聚集现象，可以更好地拟合和预测波动性。因此，当残差存在条件异方差时，引入 GARCH 模型可以更好地建模数据的波动特性。

