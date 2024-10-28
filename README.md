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
![plo](https://github.com/Tony980624/Time-series-forecasting/blob/main/file01/Rplot.png)

总体一直处于上升趋势

## 对收盘价进行差分，得到每日收盘价变化

```
r = diff(df$close)
plot(df$time[-1],r,type = 'l')
```
![plot](https://github.com/Tony980624/Time-series-forecasting/blob/main/file01/Rplot01.png)

差分后的数据(波动)趋于平稳了，而且我们观察到团簇大波动率(高波动率发生时，往往后面也是高波动率)， 所以根据初步判断GARCH模型是合适的

## 用AIC寻找模型最佳参数

之所以用AIC,而不是BIC,AIC 更注重模型的拟合效果，惩罚项相对较小，偏向于选择稍复杂的模型。适用于数据量较大或者对模型复杂度要求不严格的情况。

```
r_ts = ts(r)
info_matrix = matrix(0, nrow = 4, ncol = 4)
for (i in 1:4) {
  for (j in 1:4) {
    garch_spec = ugarchspec(variance.model=list(model="sGARCH", garchOrder=c(i,j)), mean.model=list(armaOrder=c(0,0)))
    garch_fit = ugarchfit(spec = garch_spec,data=r_ts)
    info_matrix[i,j] = infocriteria(garch_fit)[1]
  }
}
which.min(info_matrix)
```

结果指出考虑前3个残差以及3个波动的平方的影响。

## 检查残差

```
# 最佳模型
best_model =  garch_spec = ugarchspec(variance.model=list(model="sGARCH", garchOrder=c(3,3)), mean.model=list(armaOrder=c(0,0)))
best_fit = ugarchfit(spec = best_model,data = r_ts)

# Ljung-Box 检验
Box.test(residuals_std, lag = 10, type = "Ljung-Box")  # 检验标准化残差
Box.test(residuals_std^2, lag = 10, type = "Ljung-Box")  # 检验标准化残差的平方
```

无论是残差还是残差的平方都拒绝了假设：存在自相关性

```
# t-test残差均值为0
residuals_std_xts = xts(residuals_std, order.by = df$time[-1])
residuals_std_xts
t.test(as.vector(residuals_std_xts), mu = 0)
```

无法拒绝假设残差均值为0
