#import "@preview/simple-bupt-report:0.1.1": experiment-report
#show: doc => experiment-report(
  title: "《电磁场实验》实验报告",
  semester: "2025-2026学年第一学期",
  class: "2023211119",
  name: "XXX",
  student-id: "2023210XXX",
  date: "2025年11月12日",
  doc,
)
#set math.equation(numbering: "I")
= 实验二 均匀无耗媒质参量的测量

== 实验目的

1. 应用相干波节点位移法，来研究均匀无损耗媒质参量$epsilon_r$的测试

2. 了解均匀无损耗媒质中电磁波参量$lambda$、$beta$、$nu$与自由空间内电磁波参量$lambda_0$、$beta_0$、$c$的差别

== 实验原理
媒质参量一般应包括介电常数$epsilon$和磁导率$mu$两个量。它们由媒质特征方程$D = epsilon E$和$B = mu H$来表征。要确定$epsilon$、$mu$值，总是要和场量$E$ 、 $H$联系在一起，对于损耗媒质来说，$epsilon$和$mu$为复数，而且与频率有关。这里我们仅对均匀无损耗电介质的介电常数$epsilon$进行讨论（$mu_r = I$的情况），最终以测定相对介电常数$epsilon_r = epsilon / epsilon_0$来了解媒质的特性和参量。

用相干波原理和测驻波节点的方法可以确定自由空间内电磁波参量$lambda_0$、$beta_0$、$c$。对于具有$epsilon_r (mu_r = 1)$的均匀无耗媒质，无法直接测得媒质中的$lambda$、$beta$、$nu$值，不能得到媒质参量值。但是我们利用类似相干波原理装置如 @figure-2-1 所示，在$P_(r 2)$前，根据对$epsilon_r$板放置前后引起驻波节点位置变化的办法，测得相位变化值，进而测定媒质$epsilon_r$值。测定$epsilon_r$值的原理如 @figure-2-2 所示。首先固定$P_(r 1)$，移动$P_(r 2)$使$P_(r 3)$出现零指示，此时$P_(r 2)$的位置在$L_3$处。然后紧贴$P_(r 2)$的表面放置具有厚度为$delta$的待测$epsilon_r$的介质样品板，$P_(r 2)$仍处于波节点位置$L_3$，由于$epsilon_r$板的引入使$P_(r 3)$指示不再为零，如 @figure-2-2 (a)和(b)所示。

#figure(
  image("image/image-2-1.png", width: 9cm),
  caption: [$epsilon_r$值测试装置示意图],
) <figure-2-1>

我们把喇叭辐射的电磁波近似地看作平面波。设$P_(r 3)$接收喇叭处的平面波表达式为$ E_(r 2)=E_(0 r 2)e^(-j beta z) $

由于$P_(r 2)$处存在厚为$delta$的$epsilon_r$媒质板（非磁性材料的媒质$mu_r = 1$）使$P_(r 3)$处的$E_(r 1)$与$E_(r 2)$之间具有相位差（因$epsilon_r$板为无损耗，可认为$E_(r 1)$与$E_(r 2)$幅度近似相等）。

#figure(
  image("image/image-2-2.png",width: 6.9cm),
  caption: [$epsilon_r$值测试原理],
) <figure-2-2>

$ Delta phi_epsilon = beta dot 2 delta &= (2 pi)/lambda dot 2 delta = beta_0 sqrt(epsilon_r) dot 2 delta \ Delta phi_0 &= beta_0 dot 2 delta $

这里$Delta phi_0$相当于$epsilon_r$板不存在时，相应距离$2 delta$所引起的相位滞后，因此得到$z = delta$时$epsilon_r$板内总的相位滞后值为$ Delta phi = Delta phi_epsilon - Delta phi_0 = beta_0 dot 2 delta (sqrt(epsilon_r)-1) $ <fomula-2-1>

为了再次使$P_(r 3)$处实现相干波零指示接收，必须把$P_(r 2)$连同$epsilon_r$板向前推进$Delta L$#footnote[$Delta L$和$Delta l$存在混用情况]，造成一个相位增量$Delta phi$，其值为$ Delta phi = (2 pi)/lambda_0 dot 2 Delta l = beta_0 dot 2 Delta l $ <fomula-2-2>

从而补偿了$epsilon_r$板的相位滞后，使$P_(r 3)$实现零指示，如 @figure-2-2(c)所示，即有$Delta phi'= Delta phi$。

由 @fomula-2-1 和 @fomula-2-2 经整理后得
$ epsilon_r = (1 + (delta l)/delta)^2 $
$ therefore lambda = lambda_0 / sqrt(epsilon_r) = lambda_0 / (1+ (Delta l)/delta) $
$ beta = (2 pi)/lambda = beta_0 (1 + (Delta l)/delta) $
$ nu = c / sqrt(epsilon_r) = c/(1+(Delta l)/delta) $

根据测出的$epsilon_(r)$值，还可以确定该媒质与空气分界面上的反射系数和折射系数$R$、$T$。当平面波垂直投射到空气与媒质分界面时，利用边界条件得
$ R_(0 epsilon) = (eta_epsilon - eta_0)/(eta_epsilon+eta_0) = (1-sqrt(epsilon_r))/(1+sqrt(epsilon_r)) $
$ T_(0 epsilon) = (2 eta_epsilon) /(eta_epsilon+eta_0) = (2)/(1+sqrt(epsilon_r)) $

当平面电磁波由媒质向自由空间垂直投射时，相应的反射系数和折射系数为
$ R_(epsilon 0) = (eta_0 - eta_epsilon)/(eta_0+eta_epsilon) = (sqrt(epsilon_r)-1)/(sqrt(epsilon_r)+1) = -R_(0 epsilon) $
$ T_(epsilon 0) = (2 eta_0) /(eta_0 + eta_epsilon) = (2 sqrt(epsilon_r))/(sqrt(epsilon_r)+1) = sqrt(epsilon_r)T_(0 epsilon) $

由$R$，$T$表达式可看出，当测出$R$，$T$值时，也可确定相应材料的$epsilon_(r)$值。

== 实验步骤

=== 实验设备
电磁波综合测试仪、铝板（固定板、可动板）2块、玻璃板1块、被测介质板1块、塑料夹子4个、游标卡尺1个

=== 实验内容
1. 用卡尺在$epsilon_(r)$板的四周测量其厚度，并取平均值$delta$
2. 根据 @figure-2-2 (a)，(b)和(c)测出没有$epsilon_(r)$时的所有节点位置及有$epsilon_r$时对应的所有节点位置，计算其对应节点的差值，并计算其平均值$Delta L$
3. 把测试值列入 @table-2-1 #footnote([此处表格中$V$疑似应为$nu$，该问题在下文中不再重复指出。对于本实验而言，可以简单将两者等价]) 所示的表格中，并根据相应关系式，得到被测介质板的$epsilon_(r)$值、介质中的电磁波参量$lambda$、$beta$、$V$及分界面上的$R$、$T$的值
#figure(
  image("image/table_example.png", width: 10cm),
  caption: [实验二测试数据记录样表],
) <table-2-1>
=== 实验步骤
1. 整体机械调整同实验一，并测出$epsilon_(r)$板的平均厚度$delta$
2. 根据@figure-2-2(a)所示安装反射铝板、透射玻璃板，固定$P_(r 1)$、移动$P_(r 2)$、使$P_(r 3)$表头指示为零，记下$P_(r 3)$处$L$的位置，即记录不加介质板时，所有的节点为零的点
3. 将具有厚度为$delta$待测$epsilon_(r)$的介质板放在$P_(r 2)$处，紧贴$epsilon_(r)$表面，并用夹子夹紧；同时注意在放进$epsilon_(r)$板之后，$P_(r 2)$仍处于波节点$L$的位置。此时指示$P_(r 3)$不再为零
4. 将$P_(r 2)$和$epsilon_(r)$共同移动，使$P_(r 2)$由$L$移到$L'$处使$P_(r 3)$再次零指示，得到$Delta L = |L - L'|$
5. 计算$epsilon_(r)$、$lambda$、$beta$、$V$、$R$、$T$的值
== 实验数据
#figure(
  table(
    columns: 5,
    align: center,
    [*参数*], [$L_0$], [$L_2$], [$L_3$], [$L_4$],
    [$L$ (mm)], [69.585], [53.032], [36.710], [21.005],
    [$L'$ (mm)], [64.752], [48.769], [33.318], [16.100],
    [$Delta L$ (mm)], [4.833], [4.263], [3.392], [4.905],
    [$overline(Delta l)$ (mm)], table.cell(colspan: 4, [4.348]),
    [$epsilon_r$], table.cell(colspan: 4, [2.970]),
    [$Delta phi$ (rad)], table.cell(colspan: 4, [1.754]),
    [$lambda$ (mm)], table.cell(colspan: 4, [18.44]),
    [$beta_r$ (rad/m)], table.cell(colspan: 4, [340.54]),
    [$V$ (m/s)], table.cell(colspan: 4, [$1.7 times 10^8$]),
    [$R$], table.cell(colspan: 4, [-0.266]),
    [$T$], table.cell(colspan: 4, [0.734]),
  ),
  caption: [实验二测试数据记录表],
) <table-2-data>
== 实验结果整理，误差分析

=== 实验结果整理
相关基本参数如下：

$overline(delta) = (delta_1+delta_2+delta_3+delta_4)/4 = 6.01 "mm"$

$lambda_0 = 31.78 "mm"$

$beta_0 = (2 pi)/lambda_0 = 197.6 "rad/m"$

带入测量数据，计算可得：

$epsilon_r = (1+(Delta l)/delta)^2 = 2.970$

$delta phi = beta_0 dot 2 Delta l = 1.754$ (rad)

$lambda = lambda_0 / sqrt(epsilon_r) = 18.44$ (mm)

$beta_r = beta_0 dot sqrt(epsilon_r) = 340.54$ (rad/m)

$V = C / sqrt(epsilon_r) = 1.74 times 10^8$ (m/s)

$R = (1 - sqrt(epsilon_r))/(1 + sqrt(epsilon_r)) = -0.266$

$T = 2/(1 + sqrt(epsilon_r)) = 0.734$

=== 误差分析
1. 介质板厚度测量误差：使用游标卡尺测量介质板厚度时，可能存在读数误差，影响最终计算结果。
2. 节点位置测量误差：在调整$P_(r 2)$位置以实现$P_(r 3)$零指示时，可能存在定位误差，导致$Delta L$的测量不准确。
3. 环境因素影响：实验环境中的温度、湿度等因素可能影响电磁波的传播特性，从而引入误差。
4. 仪器精度限制：电磁波综合测试仪的精度限制也可能导致测量结果存在一定误差。
通过以上分析，可以看出实验结果的准确性受到多方面因素的影响，需要在实验设计和操作中加以注意，以尽量减少误差的影响。
== 思考题
1. 本实验内容用$mu_r = 1$测试均匀无损耗媒质$epsilon_(r)$值，可否测$mu_r eq.not 1$的磁介质？试说明原因。

答：本实验方法主要依赖于测量介质板引入的相位变化来确定介电常数$epsilon_r$。对于磁介质（$mu_r eq.not 1$），其磁导率的变化也会影响电磁波的传播特性，因此仅通过测量相位变化无法直接区分介电常数和磁导率的贡献。因此，本实验方法不适用于测量$mu_r eq.not 1$的磁介质。

#pagebreak()
== 附录
#figure(
  image("image/data-2-1.jpg"),
  caption: [实验二原始数据记录照片]
)
