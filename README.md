# AutoMonkey4I


AutoMonkey4I是一个基于FastMonkey开发的IOS App自动化测试工具.

FastMonkey 在XCTestWD基础上实现一个server路由，外部命令可引导启动app 并执行monkey,无需插桩、每秒可产生4-5个action  

### 简要说明:<br>
1. 支持参数化传入**测试时间、测试次数、测试端口及UDID**启动测试
2. 应用信息及登录名密码配置，config/appinfo.txt
3. 支持收集**系统日志(Systemlog)**、**崩溃日志(Crashlog)**、**事件操作日志(Eventlog)**
4. 支持自动**生成测试报告**
5. 支持多台设备同时测试及测试设备信息收集
6. FastMonkey框架添加登录功能及长时返回
7. 启用监控，FastMonkey中WD进程挂掉，自动重启并继续测试   

<br>
### 系统要求:
**MacOS High Sierra  版本10.13**

**Xcode 9.0及以上**

**IOS 9.0 及以上**

<br>
### 依赖及配置:
Homebrew、zsh、JDK、Xcode9、**xcode command line tools、jq , 改进libimobiledevice**
<br><br>
1，安装xcode command line tools, 终端输入命令 
    `xcode-select --install`回车后，按正常软件安装程序安装
<br> <br>
2，安装jq， `brew install jq` 回车  
<br><br>
3，**[安装改进版libimobiledevice](http://work.intra.yiguanjinrong.com/gitlab/yiguan-test/AutoMonkey4I/wikis/%E5%AE%89%E8%A3%85libimobiledevice)**

<br>
### 使用说明:
<br>
2，**更新依赖**
<br><br>
进入目录`cd xxxxx/AutoMonkey4I/XCTestWD-master`

更新第三方库 `carthage update`
<br><br>
3，**安装系统证书**
<br><br>
AutoMonkey4I/Certificates 目录
<br><br>
4，**Xcode导入Provisioning Profile**
<br><br>
    1）进入目录AutoMonkey4I/XCTestWD-master/XCTestWD, 打开XCTestWD.xcodeproj
<br><br>
    2）Xcode中，XCTestWD->General->Signing，取消勾选Automatically manage signing， 
    Provisioning Profile选择导入Certificates中
<br><br>
    3）XCTestWDUITests->General->Signing， 选择同一Provisioning Profile
<br><br>
5，**应用信息配置**
<br><br>
**AutoMonkey4I/config目录下, appinfo.txt**

**Json数据格式：可支持多app测试**, 应用名、bundleId、用户名、密码。<br>
如果无需登录，用户及密码设空即可   
<br>
`[
    {
        "appName": "xxx",
        "bundleId": "xxx",
        "username": "13500000002",
        "password": "aaa123"
    },
    {
        "appName": “Crasher",
        "bundleId": “com.yiguantest.crash",
        "username": "",
        "password": ""
    }
]`
<br><br>
6，**执行命令**
<br><br>
AutoMonkey4I 主目录, [说明]
<br><br>
**入口: start_monkey.sh, 四个参数, -u udid、 -p port、-t run_time、-n loop_num**
<br><br>
**用法：四个参数皆为可选，没有相应参数时，使用默认值**
<br><br>
1)  `./start_monkey.sh`
<br><br>
默认执行： 设备:连接pc的设备列表中的第一台、端口:8001、时间:60分钟、次数: 2
<br><br>
2)  `./start_monkey.sh -u e55f18280b4f924b7cecca5d180bec93e654f351 -t 120m`
<br><br>
默认执行： 设备:指定此udid的设备、时间:120分钟、次数及端口为默认值
<br>

### 测试报告:
<br>
**./output下相应时间的文件夹中**
<br>
***Summary:***
<br>
<br>

### 附加说明
<br>
***自动登录:***<br>
在FastMonkey中，实现参数化用户名及密码，间隔进行界面检查如符合登录界面并未登录，自动进行登录原子操作.<br>
登录界面检查及登录逻辑基于一贯应用实现，如需测试其他应用，则要实现相关逻辑<br><br>
***长时返回:***<br>
在FastMonkey中，实现长时间隔检查，如果停留在同一页面则按返回到应用主界面.<br>
检查页面及返回操作基于一贯应用实现，如需测试其他应用，则要实现相关逻辑<br><br>
***以上两种功能在测试其他应用需单独实现 ，不实现也可以进行测试，只是没有相关功能***
<br><br>

### 相关参考
<br>
**[Homebrew:http://www.jianshu.com/p/d229ac7fe77d](http://www.jianshu.com/p/d229ac7fe77d)**<br>
**[zsh:http://www.jianshu.com/p/ae378aa725cf](http://www.jianshu.com/p/ae378aa725cf)**<br>
**[FastMonkey: https://github.com/zhangzhao4444/Fastmonkey](https://github.com/zhangzhao4444/Fastmonkey)**<br>
**[libimobiledevice: https://testerhome.com/topics/8069](https://testerhome.com/topics/8069)**<br>
**[jq:http://blog.sina.com.cn/s/blog_56ae1d580102xv7d.html](http://blog.sina.com.cn/s/blog_56ae1d580102xv7d.html)**<br>
**[xcodebuild:https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/xcodebuild.1.html](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/xcodebuild.1.html)**<br>
**[IOS签名证书:http://www.jianshu.com/p/9d9e3699515e](http://www.jianshu.com/p/9d9e3699515e)**<br>



