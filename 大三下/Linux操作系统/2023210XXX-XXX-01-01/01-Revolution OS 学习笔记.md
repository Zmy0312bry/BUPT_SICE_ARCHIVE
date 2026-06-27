# Revolution OS 学习笔记

> 此记录电影主要介绍了Linux操作系统和`Free Software Movement`之间的关系。

## Linux

1. 发明人：Linus Torvalds[^1]

2. 起源：自由软件运动[^5]和GNU[^2] Project的合作
3. 许可方式：GPL[^3]
4. 软件类型：操作系统(Operation System)[^4]
5. 架构：宏内核

## 自由软件运动

1. 创始人：Richard Stallman
2. 发起原因：Richard Stallman认为以Microsoft为代表的公司对软件版权的封闭管理和分发模式阻碍了他去“做一些有益的工作”。
3. 代表组织：Free Software Foundation(FSF)[^6]
4. 代表项目：GNU Project[^7]
5. 核心概念：自由软件(Free Software)
   1. have a copyleft[^8]
   2. have an owner
   3. have a license
   4. not public domain

## GNU Project

1. 目标：创建一套完全自由的操作系统
2. 内核计划：
   1. Hurd计划：微内核架构
      - 优点：先进、高效
      - 缺点：异步逻辑、调试困难
   2. Linux：宏内核架构
      - 优点：成熟、稳定、已经经过测试
      - 缺点：技术相对保守

## 变革的流程

1. 互联网的普及，催生了`Apache Web Server`这样的关键软件
2. 出现了依赖Linux的相关公司
3. 商业巨头的转向：Netscape(网景公司)，决定开源其浏览器源代码[^9]

4. 黄金时期：1999年8月10日，LinuxWorld大会召开；第二天，Red Hat公司成功上市。

[^1]: Linux内核作者、`Git`的发起人和主要开发者。
[^2]: GNU is Gnu's Not Unix.
[^3]: GNU General Public Licenses, visit [WikiPedia](https://en.wikipedia.org/wiki/GNU_General_Public_License) for more information.
[^4]: An operation system "helps programs run and connect to the outside world." -- Linus Torvalds
[^5]: Free Software Movement. Free as is freedom.
[^6]: https://www.fsf.org
[^7]: https://www.gnu.org
[^8]: 源自Free Software Movement，是一种利用现有著作权体制来保障用户软件自由使用权利的许可方式『摘自[WikiPedia](https://zh.wikipedia.org/zh-cn/Copyleft)』
[^9]: 此次开源行为的另一个产物是[Mozilla](https://www.mozilla.org)，Firefox浏览器的发明组织