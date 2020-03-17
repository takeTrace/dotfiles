# 备份

1. 软链备份

有些东西可以通过 mackup 来管理, 它已经通过软链, 把实际文件放在自己管理的目录下, 带走这个目录就可以了, 在这之前, 先最后 backup 一下, 保证东西都是最新的

```sh
mackup backup -f
```

有些应用, 不能通过命令行来备份, 里面的数据是自己管理. 需要做一个导出备份的操作, 导出地址直接是 mackup 管理的目录就可以了. 当前电脑上需要导出备份的应用

- Chrome/Safari/Firefox 书签导出到~/Backup/Bookmark/, 并点击一下在线同步
- MarginNote 导出备份
- .Sync 文件里面东西目前优点多, 有点乱, 所以, 需要单独拷贝出来
- Eudic 欧陆词典配置备份
- keychains 备份
- Chrome 插件 `Dark Reader` 配置备份: sync_storage_Dark Reader.json
- conda env export -f ~/Backup/CondaEnv/环境名 -n 环境名

