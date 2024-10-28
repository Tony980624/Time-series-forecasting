df = read.csv('D:/STATA/XAUUSD_data.csv')
df = data.frame(time = as.Date(df[,1]), close = df[,5])
plot(df,type='l')

train_index = c(1:1800)
train_data = df[train_index,]
test_data = df[-train_index,]
r = diff(train_data$close)
plot(train_data$time[-1],r,type = 'l',ylab='return',xlab = '')



library(forecast)
library(dplyr)
library(rugarch)

ARMA_est = list()
ic_arma = matrix( nrow = 4 * 4, ncol = 4 )
colnames(ic_arma) <- c("p", "q", "aic", "bic")
for (p in 0:3)
{
  for (q in 0:3)
  {
    i = p * 4 + q + 1
    ARMA_est[[i]] = Arima(r, order = c(p, 0, q))
    ic_arma[i,] = c(p, q, ARMA_est[[i]]$aic, ARMA_est[[i]]$bic)
  }
}
ic_aic_arma = ic_arma[order(ic_arma[,3]),][1:10,]
ic_bic_arma = ic_arma[order(ic_arma[,4]),][1:10,]
ic_int_arma = intersect(as.data.frame(ic_aic_arma),
                         as.data.frame(ic_bic_arma))
adq_set_arma = as.matrix(arrange(as.data.frame(
  rbind(ic_int_arma[c(1:3, 6),],
        ic_bic_arma[2,])), p, q))
adq_idx_arma = match(data.frame(t(adq_set_arma[, 1:2])),
                      data.frame(t(ic_arma[, 1:2])))
nmods = min(length(adq_idx_arma), 2)
for (i in 1:nmods)
{
  checkresiduals(ARMA_est[[adq_idx_arma[i]]])
}



e2_arma = list()
for (i in 1:nmods)
{
  e2_arma[[i]] <- resid(ARMA_est[[adq_idx_arma[i]]]) 
  title_p_q <- paste("ARMA(",
                     as.character(adq_set_arma[i, 1]), ", ",
                     as.character(adq_set_arma[i, 2]), ")",
                     sep = "")
  plot(train_data$time[-1], e2_arma[[i]], type = "l",
       xlab = "", ylab = "squared resid",
       main = paste("Plot: ", title_p_q))
  acf(e2_arma[[i]], xlab = "", ylab = "",
      main = paste("SACF: ", title_p_q))
}

# Squared residuals appear to be strongly autocorrelated even though autocorrelation
# in the residual levels appears to be quite low. We interpret this as evidence of
# conditional heteroscedasticity possibly being present in the

bptest <- matrix(nrow = 10 * nmods, ncol = 5)
colnames(bptest) <- c("p", "q", "j", "LM-stat", "p-value")
for (i in 1:nmods)
{
  e2_i <- as.vector(e2_arma[[i]])
  f <- formula(e2_i ~ 1)
  for (j in 1:10)
  {
    # lag lengths in the auto-regression of squared residuals
    k <- 10 * (i - 1) + j
    f <- update.formula(f, paste("~ . + lag(e2_i, n = ", j, ")"));
    bp_reg_j <- lm(f)
    LM_j <- length(e2_i) * summary(bp_reg_j)$r.squared
    p_val_j <- 1 - pchisq(LM_j, df = j)
    bptest[k,] <- c(adq_set_arma[i, 1:2], j, LM_j, p_val_j)
  }
}

ARMA_GARCH_est <- list()
ic_arma_garch <- matrix(nrow = 3^4, ncol = 6)
colnames(ic_arma_garch) <- c("pm", "qm", "ph", "qh", "aic", "bic")
i <- 0
for (pm in 0:2) {
  for (qm in 0:2) {
    for (ph in 0:2) {
      for (qh in 0:2) {
        i <- i + 1
        ic_arma_garch[i, 1:4] <- c(pm, qm, ph, qh)
        if (ph == 0 && qh == 0) {
          # 对于常方差模型，使用 arfimaspec 和 arfimafit
          ARMA_GARCH_mod <- arfimaspec(
            mean.model = list(armaOrder = c(pm, qm))
          )
          ARMA_GARCH_est[[i]] <- arfimafit(ARMA_GARCH_mod, r)
          ic_arma_garch[i, 5:6] <- infocriteria(
            ARMA_GARCH_est[[i]]
          )[1:2]
        } else {
          try(silent = TRUE, expr = {
            ARMA_GARCH_mod <- ugarchspec(
              mean.model = list(armaOrder = c(pm, qm)),
              variance.model = list(garchOrder = c(ph, qh))
            )
            ARMA_GARCH_est[[i]] <- ugarchfit(ARMA_GARCH_mod, r, solver = 'hybrid')
            ic_arma_garch[i, 5:6] <- infocriteria(
              ARMA_GARCH_est[[i]]
            )[1:2]
          })
        }
      }
    }
  }
}

# 按 AIC 和 BIC 选择前 40 个模型
ic_aic_arma_garch <- ic_arma_garch[order(ic_arma_garch[, 5]), ][1:40, ]
ic_bic_arma_garch <- ic_arma_garch[order(ic_arma_garch[, 6]), ][1:40, ]
ic_int_arma_garch <- intersect(as.data.frame(ic_aic_arma_garch),
                               as.data.frame(ic_bic_arma_garch))  # 修正为闭合括号

# 提取前 36 个合适的模型组合并按阶数排序
adq_set_arma_garch <- as.matrix(arrange(as.data.frame(
  ic_int_arma_garch[1:36, ]), pm, qm, ph, qh))  # 增加闭合括号

# 获取最终模型的索引
adq_idx_arma_garch <- match(
  data.frame(t(adq_set_arma_garch[, 1:4])),
  data.frame(t(ic_arma_garch[, 1:4]))
)

# 计算自相关系数（ACF）
nmods <- length(adq_idx_arma_garch)
sacf_garch <- matrix(nrow = nmods, ncol = 14)
colnames(sacf_garch) <- c("pm", "qm", "ph", "qh", 1:10)
for (i in 1:nmods) {
  sacf_garch[i, 1:4] <- adq_set_arma_garch[i, 1:4]
  sacf_garch[i, 5:14] <-
    acf(ARMA_GARCH_est[[adq_idx_arma_garch[i]]]@fit$z,
        lag = 10, plot = FALSE)$acf[2:11]
}


# 计算真实的波动率（通常为收益率的平方）
real_volatility <- r^2  # 这里 r 是收益率序列（差分计算得到）

# 遍历每个模型，将预测波动率与真实波动率绘制在同一张图上
for (i in 1:nmods) {
  # 生成模型标题
  title_p_q <- paste("ARMA(",
                     as.character(adq_set_arma_garch[i, 1]), ", ",
                     as.character(adq_set_arma_garch[i, 2]),
                     ")-GARCH(",
                     as.character(adq_set_arma_garch[i, 3]), ", ",
                     as.character(adq_set_arma_garch[i, 4]), ")",
                     sep = "")
  
  # 提取预测的波动率（条件方差）
  predicted_volatility <- ARMA_GARCH_est[[adq_idx_arma_garch[i]]]@fit$var
  
  # 绘制真实波动率和预测波动率在同一张图上
  plot(train_data$time[-1], real_volatility, type = "l", col = "blue",
       xlab = "", ylab = "Volatility", main = title_p_q, lwd = 1.5)
  lines(train_data$time[-1], predicted_volatility, col = "red", lwd = 1.5)
  
  # 添加图例
  legend("topright", legend = c("真实波动率", "预测波动率"), 
         col = c("blue", "red"), lty = 1, lwd = 1.5)
}
